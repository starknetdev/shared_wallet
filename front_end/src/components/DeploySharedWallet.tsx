import styles from '../styles/components/DeploySharedWallet.module.css'
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

export const DeploySharedWallet = () => {
    const { account } = useStarknet()
    const [amount, setAmount] = useState('')
    const [amountError, setAmountError] = useState<string | undefined>()

    const [inputList, setInputList] = useState([
        { input: "" }
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

    const handleInputAdd = () => {
        setInputList([...inputList, { input: "" }])
    }

    return (
        <div className={styles.row}>
            <h3>Tokens</h3>
            {inputList.map((input, index) =>
                <>
                    <div className={styles.input} key={index}>
                        <span>Token {index + 1} Amount: </span>
                        <input type="number" onChange={(evt) => updateAmount(evt.target.value)} />
                    </div>
                    {inputList.length - 1 === index && inputList.length < 3 &&
                        (
                            <button className={styles.add} onClick={handleInputAdd}>
                                <FontAwesomeIcon icon={faCirclePlus} />
                            </button>
                        )}
                </>
            )}
            <h3>Composition</h3>
            <button>

                Deploy
            </button>
        </div>
    )
}