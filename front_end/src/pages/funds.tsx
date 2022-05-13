import styles from '../styles/Funds.module.css'
import type { NextPage } from 'next'
import { UserBalances } from '~/components/UserBalances'
import { TransactionList } from '~/components/TransactionList'
import { MintToken } from "~/components/MintToken"
import { Main } from "../features/Main"
import { CreateFund } from '~/components/CreateFund'
import { FundsList } from '~/components/FundsList'

const CreateFundPage: NextPage = () => {
    const { supportedTokens } = Main()

    return (
        <div className={styles.container}>
            <h2>Create Fund</h2>
            <CreateFund />
            <h2>Funds</h2>

        </div>
    )
}

export default CreateFundPage
