import styles from '../styles/CreateFund.module.css'
import type { NextPage } from 'next'
import { UserBalances } from '~/components/UserBalances'
import { TransactionList } from '~/components/TransactionList'
import { MintToken } from "~/components/MintToken"
import { Main } from "../features/Main"
import { DeploySharedWallet } from '~/components/DeploySharedWallet'

const CreateFundPage: NextPage = () => {
    const { supportedTokens } = Main()

    return (
        <div className={styles.container}>
            <h2>Create Shared Wallet</h2>
            <DeploySharedWallet />
        </div>
    )
}

export default CreateFundPage
