import styles from '../styles/components/FundsList.module.css'
import {
    useStarknet,
    useStarknetInvoke,
    Transaction,
    useStarknetTransactionManager,
    useStarknetCall
} from '@starknet-react/core'
import {
    useCallback,
    useState
} from 'react'
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome'
import { toBN } from 'starknet/dist/utils/number'
import { faCirclePlus } from '@fortawesome/free-solid-svg-icons'
import { useTokenContract } from '~/hooks/token'
import deploymentsConfig from "../../deployments-config.json"

export const FundsList = () => {
    const address = deploymentsConfig["networks"]["goerli"]["fund_factory"]
    const { contract } = useTokenContract(address)
    const { data, loading, error } = useStarknetCall({
        contract,
        method: 'get_funds',
        args: undefined,
    })

    return (
        <div>
            {data?.map((fund, index) =>
                <>
                    <div className={styles.input} key={index}>
                        <p>Fund: {fund}</p>
                    </div>
                </>
            )}
        </div>
    )
}