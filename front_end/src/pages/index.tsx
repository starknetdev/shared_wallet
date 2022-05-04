import type { NextPage } from 'next'
import { UserBalances } from '~/components/UserBalances'
import { TransactionList } from '~/components/TransactionList'
import { MintToken } from "~/components/MintToken"
import { Main } from "../features/Main"

const Home: NextPage = () => {
  const { supportedTokens } = Main()

  return (
    <div>
      <UserBalances supportedTokens={supportedTokens} />
      {/* <MintTokens supportedTokens={supportedTokens} /> */}
      <MintToken supportedTokens={supportedTokens} />
      <TransactionList />
    </div>
  )
}

export default Home
