import { useContract } from '@starknet-react/core'
import { Abi } from 'starknet'

import Erc20Abi from '~/abi/erc20.json'

export function useTokenContract() {
  return useContract({
    abi: Erc20Abi as Abi,
    address: '0x06d473b23ac1779cc748e835b3ed1f0c07aeadf6db49e15d1de3cf3c1e733f65',
  })
}
