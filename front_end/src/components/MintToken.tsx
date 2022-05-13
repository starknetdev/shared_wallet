import styles from '../styles/Home.module.css'
import {
    useStarknet,
    useStarknetCall,
    useStarknetInvoke,
    Transaction,
    useStarknetTransactionManager
} from '@starknet-react/core'
import {
    useCallback,
    useMemo,
    useState,
    useEffect
} from 'react'
import { toBN } from 'starknet/dist/utils/number'
import { bnToUint256, uint256ToBN } from 'starknet/dist/utils/uint256'
import { useTokenContract } from '~/hooks/token'
import { Token } from '../features/Main'

interface MintTokenProps {
    supportedTokens: Array<Token>;
}

interface MintProps {
    token: Token
}

function Mint({ token }: MintProps) {
    const { account } = useStarknet()
    const [amount, setAmount] = useState('')
    const [amountError, setAmountError] = useState<string | undefined>()

    const { contract } = useTokenContract(token.address)

    const { loading, error, reset, invoke } = useStarknetInvoke({ contract, method: 'mint' })


    const updateAmount = useCallback(
        (newAmount: string) => {
            // soft-validate amount
            setAmount(newAmount)
            try {
                toBN(newAmount)
                setAmountError(undefined)
            } catch (err) {
                console.error(err)
                setAmountError('Please input a valid number')
            }
        },
        [setAmount]
    )

    const onMint = useCallback(() => {
        reset()
        if (account && !amountError) {
            const message = `${amount.toString()} tokens to ${account}`
            const amountBn = bnToUint256(amount)
            invoke({ args: [account, amountBn] })
        }
    }, [account, amount])

    const mintButtonDisabled = useMemo(() => {
        if (loading) return true
        return !account || !!amountError
    }, [loading, account, amountError])

    return (
        <>
            <p>
                <span>{token.name} - Amount: </span>
                <input type="number" onChange={(evt) => updateAmount(evt.target.value)} />
            </p>
            <button disabled={mintButtonDisabled} onClick={onMint}>
                {loading ? 'Waiting for wallet' : 'Mint'}
            </button>
            {error && <p>Error: {error}</p>}
        </>
    )

}

export function MintToken({ supportedTokens }: MintTokenProps) {

    return (
        <div className={styles.container}>
            <h2>Mint tokens</h2>
            {supportedTokens.map((token, index) =>
                <Mint token={token} key={index} />
            )}
        </div>
    )
}