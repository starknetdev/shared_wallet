import { useContract } from '@starknet-react/core'
import { Abi } from 'starknet'

import SharedWalletAbi from '~/abi/SharedWallet.json'

export function useSharedWalletContract() {
    return useContract({
        abi: SharedWalletAbi as Abi,
        address: '0',
    })
}
