import styles from '../styles/components/CreateProposal.module.css'
import {
    useStarknet,
    useStarknetInvoke,
    Transaction,
    useStarknetTransactionManager
} from '@starknet-react/core'
import {
    useCallback,
    useState
} from 'react'
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome'
import { toBN } from 'starknet/dist/utils/number'
import { faCirclePlus } from '@fortawesome/free-solid-svg-icons'

export const CreateProposal = () => {
    const { account } = useStarknet()
    const [amount, setAmount] = useState('')
    const [amountError, setAmountError] = useState<string | undefined>()

    const [votingParamsList, setVotingParamsList] = useState([
        { votingParam: "" }
    ])
    const [executionParamsList, setExecutionParamsList] = useState([
        { executionParams: "" }
    ])

    const updateAmount = useCallback(
        (newAmount: string) => {
            // soft-validate amount
            setAmount(newAmount)
            try {
                toBN(newAmount)
                setAmountError(undefined)
            } catch (err) {
                console.error(err)
                setAmountError('Please input a valid number')
            }
        },
        [setAmount]
    )

    const handleVotingParamsAdd = () => {
        setVotingParamsList([...votingParamsList, { votingParam: "" }])
    }
    const handleExecutionParamsAdd = () => {
        setExecutionParamsList([...executionParamsList, { executionParams: "" }])
    }

    return (
        <div className={styles.container}>
            <h3>Execution Hash</h3>
            <input type="number" onChange={(evt) => updateAmount(evt.target.value)} />
            <h3>Metadata URI</h3>
            <input type="text" onChange={(evt) => updateAmount(evt.target.value)} />
            <h3>ETH Block Number</h3>
            <input type="number" onChange={(evt) => updateAmount(evt.target.value)} />
            <h3>Voting Params</h3>
            {votingParamsList.map((votingParam, index) =>
                <>
                    <div className={styles.input} key={index}>
                        <span>Param {index + 1}: </span>
                        <input type="text" onChange={(evt) => updateAmount(evt.target.value)} />
                    </div>
                    {votingParamsList.length - 1 === index && votingParamsList.length < 10 &&
                        (
                            <button className={styles.add} onClick={handleVotingParamsAdd}>
                                <FontAwesomeIcon icon={faCirclePlus} />
                            </button>
                        )}
                </>
            )}
            <h3>Execution Params</h3>
            {executionParamsList.map((votingParam, index) =>
                <>
                    <div className={styles.input} key={index}>
                        <span>Param {index + 1}: </span>
                        <input type="text" onChange={(evt) => updateAmount(evt.target.value)} />
                    </div>
                    {executionParamsList.length - 1 === index && executionParamsList.length < 10 &&
                        (
                            <button className={styles.add} onClick={handleExecutionParamsAdd}>
                                <FontAwesomeIcon icon={faCirclePlus} />
                            </button>
                        )}
                </>
            )}
            <button>
                Create Proposal
            </button>
        </div>
    )
}