import styles from '../styles/Votes.module.css'
import type { NextPage } from 'next'
import { UserBalances } from '~/components/UserBalances'
import { TransactionList } from '~/components/TransactionList'
import { MintToken } from "~/components/MintToken"
import { Main } from "../features/Main"

const VotesPage: NextPage = () => {
    const { supportedTokens } = Main()

    return (
        <div className={styles.container}>
            <h2>Votes</h2>
        </div>
    )
}

export default VotesPage
