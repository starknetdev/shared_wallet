import styles from '../styles/Funds.module.css'
import type { NextPage } from 'next'
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
            <FundsList />
        </div>
    )
}

export default CreateFundPage
