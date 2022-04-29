import { useContract } from '@starknet-react/core'
import { Abi } from 'starknet'

import SharedWalletAbi from '~/abi/shared_wallet.json'

export function useTokenContract() {
    return useContract({
        abi: SharedWalletAbi as Abi,
        address: '0x073eb46188f6eb6de338f68ee091631d46e596aaecf3a01c5742fccc9f14ae0a',
    })
}
