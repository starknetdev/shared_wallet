import type { NextPage } from 'next'
import { UserBalances } from '~/components/UserBalances'
import { TransactionList } from '~/components/TransactionList'
import { MintToken } from "~/components/MintToken"
import { Main } from "../features/Main"

const CreateProposalPage: NextPage = () => {
    const { supportedTokens } = Main()

    return (
        <div>
            <p>Create Proposal</p>
        </div>
    )
}

export default CreateProposalPage
