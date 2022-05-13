import styles from '../styles/Proposals.module.css'
import type { NextPage } from 'next'
import { UserBalances } from '~/components/UserBalances'
import { TransactionList } from '~/components/TransactionList'
import { MintToken } from "~/components/MintToken"
import { Main } from "../features/Main"
import { CreateProposal } from '~/components/CreateProposal'

const CreateProposalPage: NextPage = () => {
    const { supportedTokens } = Main()

    return (
        <div className={styles.container}>
            <h2>Create Proposal</h2>
            <CreateProposal />
            <h2>Proposals</h2>
        </div>
    )
}

export default CreateProposalPage
