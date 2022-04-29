import { useStarknet, InjectedConnector, useStarknetInvoke } from '@starknet-react/core'
import { useCallback, useMemo, useState } from 'react'
import { toBN } from 'starknet/dist/utils/number'
import { bnToUint256, uint256ToBN } from 'starknet/dist/utils/uint256'
import { useTokenContract } from '~/hooks/token'


export function Deposit() {
    const { account, connect } = useStarknet()
    const { contract } = useTokenContract()

    const [amount, setAmount] = useState('')
    const [amountError, setAmountError] = useState<string | undefined>()

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

    const onInititialize = useCallback(() => {
        reset()
        if (account) {
            invoke({ args: [account] })
        }
    }, [account])

    const onDeposit = useCallback(() => {
        reset()
        if (account && !amountError) {
            const amountBn = bnToUint256(amount)
            invoke({ args: [account, amountBn] })
        }
    }, [account, amount])

    const initializeOwnerButtonDisabled = useMemo(() => {
        if (loading) return true
    }, [loading, account])

    const depositButtonDisabled = useMemo(() => {
        if (loading) return true
        return !account || !!amountError
    }, [loading, account, amountError])


    return (
        <div>
            <h2>Inititialize Owner</h2>
            <button disabled={depositButtonDisabled} ></button>

            <h2>Deposit Tokens</h2>
            <p>
                <span>Amount: </span>
                <input type="number" onChange={(evt) => updateAmount(evt.target.value)} />
            </p>
            <button disabled={depositButtonDisabled} onClick={onDeposit}>
                {loading ? 'Waiting for wallet' : 'Deposit'}
            </button>
            {error && <p>Error: {error}</p>}
        </div>
    )
}
