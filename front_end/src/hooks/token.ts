import { useContract } from '@starknet-react/core'
import { Abi } from 'starknet'

import Erc20Abi from '~/abi/erc20.json'

export function useTokenContract(address: string) {
  return useContract({
    abi: Erc20Abi as Abi,
    address: address,
  })
}
