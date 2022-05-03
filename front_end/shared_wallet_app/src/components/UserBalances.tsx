import styles from '../styles/Home.module.css'
import { useStarknet, useStarknetCall } from '@starknet-react/core'
import { useTokenContract } from '~/hooks/token'
import { uint256ToBN } from 'starknet/dist/utils/uint256'
import { useMemo } from 'react'
import { Token } from '../features/Main'
import Image from 'next/image'

interface UserBalancesProps {
    supportedTokens: Array<Token>;
}

export const UserBalances = ({ supportedTokens }: UserBalancesProps) => {
    const { account } = useStarknet()

    const GetBalance = (address: string, index: number) => {
        const { contract } = useTokenContract(address)
        const { data, loading, error } = useStarknetCall({
            contract,
            method: 'balanceOf',
            args: account ? [account] : undefined,
        })

        const content = useMemo(() => {
            if (!data?.length) {
                return <div>Please connect wallet</div>
            }

            if (loading) {
                return <div>Loading balance</div>
            }

            if (error) {
                return <div>Error: {error}</div>
            }
            console.log(error)
            const balance = uint256ToBN(data[0])
            return <div>{balance.toString(10)}</div>
        }, [data, loading, error])

        return (
            <div key={index}>
                {content}
            </div>
        )
    }

    return (
        <div className={styles.container}>
            <h2>Token Balances</h2>
            <div>
                {supportedTokens.map((token, index) =>
                    <>
                        <div>
                            <Image className={styles.token_image} src={token.image} alt={token.slug + "-image"} key={index} width={20} height={20} />
                            <p>{token.name}</p>
                        </div>
                        <div>
                            {GetBalance(token.address, index)}
                        </div>
                    </>
                )}
            </div>
        </div>
    )
}