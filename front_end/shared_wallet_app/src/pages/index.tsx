import styles from '../styles/Home.module.css'
import { useStarknet, useStarknetCall, useStarknetInvoke } from '@starknet-react/core'
import type { NextPage } from 'next'
import { useCallback, useMemo, useState } from 'react'
import { toBN } from 'starknet/dist/utils/number'
import { bnToUint256, uint256ToBN } from 'starknet/dist/utils/uint256'
import { Navbar } from '~/components/Navbar'
import { UserBalances } from '~/components/UserBalances'
import { TransactionList } from '~/components/TransactionList'
import { MintToken } from "~/components/MintToken"
import { MintTokens } from "~/components/MintTokens"
import { Main } from "../features/Main"

const TokenPage: NextPage = () => {
  const { account } = useStarknet()
  const { supportedTokens } = Main()

  return (
    <div>
      <Navbar />
      <UserBalances supportedTokens={supportedTokens} />
      {/* <MintTokens supportedTokens={supportedTokens} /> */}
      <MintToken supportedTokens={supportedTokens} />
      <TransactionList />
    </div>
  )
}

export default TokenPage
