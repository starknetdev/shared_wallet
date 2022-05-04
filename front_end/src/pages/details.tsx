import type { NextPage } from 'next'
import { UserBalances } from '~/components/UserBalances'
import { TransactionList } from '~/components/TransactionList'
import { MintToken } from "~/components/MintToken"
import { Main } from "../features/Main"

const DetailsPage: NextPage = () => {
    const { supportedTokens } = Main()

    return (
        <div>
            <p>Hello my name is Sam</p>
        </div>
    )
}

export default DetailsPage
