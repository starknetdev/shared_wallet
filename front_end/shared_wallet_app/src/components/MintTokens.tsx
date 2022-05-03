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
import loadConfig from 'next/dist/server/config'

interface MintTokensProps {
    supportedTokens: Array<Token>;
}

function Mint(account: any, amount: string, amountError: string | undefined, address: string) {
    const { contract } = useTokenContract(address)
    const { loading, error, reset, invoke } = useStarknetInvoke({ contract, method: 'mint' })
    reset()
    const amountBn = bnToUint256(amount)
    invoke({ args: [account, amountBn] })

    // const onMint = useCallback(() => {
    //     reset()
    //     if (account && !amountError) {
    //         const amountBn = bnToUint256(amount)
    //         invoke({ args: [account, amountBn] })
    //     }
    // }, [account, amount])


    const mintButtonDisabled = useMemo(() => {
        if (loading) return true
        return !account || !!amountError
    }, [loading, account, amountError])

    return { loading, error, mintButtonDisabled }
}

export const MintTokens = ({ supportedTokens }: MintTokensProps) => {
    const { account } = useStarknet()
    const [amount, setAmount] = useState('')
    const [amountError, setAmountError] = useState<string | undefined>()
    const { transactions } = useStarknetTransactionManager()

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

    const onMintTokens = () => {
        if (account && !amountError) {
            supportedTokens.map((token, index) => {
                const { loading, mintButtonDisabled, error } = Mint(account, amount, amountError, token.address)
                return (
                    <>
                        <button disabled={mintButtonDisabled} onClick={onMintTokens}>
                            {loading ? 'Waiting for wallet' : 'Mint test tokens'}
                        </button>
                        {error && <p>Error: {error}</p>}
                    </>
                )
            })
        }
    }

    // useEffect(() => {
    //     if (
    //         transactions.filter(
    //             (transaction) =>
    //                 transaction.status === "TRANSACTION_RECEIVED" &&
    //                 transaction.transactionName === "Approve ERC20 transfer"
    //         ).length > 0
    //     ) {
    //         !showApprovalSuccess && setShowApprovalSuccess(true)
    //     }
    // }, [notifications, showApprovalSuccess, showProvideLiquiditySuccess])

    // return (
    //     <div className={styles.container}>
    //         <h2>Mint test tokens</h2>
    //         <p>
    //             <span>Amount: </span>
    //             <input type="number" onChange={(evt) => updateAmount(evt.target.value)} />
    //         </p>
    //         <button disabled={mintButtonDisabled} onClick={onMintTokens}>
    //             {loading ? 'Waiting for wallet' : 'Mint test tokens'}
    //         </button>
    //         {onMintTokens()}
    //     </div>
    // )
}