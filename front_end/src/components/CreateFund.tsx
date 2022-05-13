import styles from '../styles/components/CreateFund.module.css'
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

export const CreateFund = () => {
    const { account } = useStarknet()
    const [amount, setAmount] = useState('')
    const [amountError, setAmountError] = useState<string | undefined>()

    const [ownerList, setOwnerList] = useState([
        { owner: "" }
    ])
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

    const handleOwnerAdd = () => {
        setOwnerList([...ownerList, { owner: "" }])
    }
    const handleInputAdd = () => {
        setInputList([...inputList, { input: "" }])
    }

    return (
        <div className={styles.container}>
            <h3>Owners</h3>
            {ownerList.map((input, index) =>
                <>
                    <div className={styles.input} key={index}>
                        <span>Owner {index + 1}: </span>
                        <input type="text" onChange={(evt) => updateAmount(evt.target.value)} />
                    </div>
                    {ownerList.length - 1 === index && ownerList.length < 10 &&
                        (
                            <button className={styles.add} onClick={handleOwnerAdd}>
                                <FontAwesomeIcon icon={faCirclePlus} />
                            </button>
                        )}
                </>
            )}
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
            {inputList.map((input, index) =>
                <>
                    <div className={styles.input} key={index}>
                        <span>Token {index + 1} Composition: </span>
                        <input type="number" onChange={(evt) => updateAmount(evt.target.value)} />
                    </div>
                </>
            )}

            <button>

                Deploy
            </button>
        </div>
    )
}