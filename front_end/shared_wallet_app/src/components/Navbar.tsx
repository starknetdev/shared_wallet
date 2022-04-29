import { useStarknet, InjectedConnector, useStarknetInvoke } from '@starknet-react/core'


export const Navbar = () => {

    const { account, connect } = useStarknet()


    return (
        <div className="navbar">
            <div className="navbar__wallet">
                {account ? (
                    <div>
                        <button className="navbar__wallet-address-button">
                            <p>{`${account?.slice(0, 5)}...${account?.slice(-4)}`}</p>
                        </button>
                    </div>
                ) : (
                    <button className="navbar__wallet-connect-button"
                        onClick={() => connect(new InjectedConnector())}
                    >
                        <p>Connect</p>
                    </button>
                )}
            </div>
        </div>

    )
}