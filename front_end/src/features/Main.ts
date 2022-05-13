import eth from "../assets/eth.png"
import dai from "../assets/dai.png"
import usdc from "../assets/usdc.png"
import deploymentsConfig from "../../deployments-config.json"

export type Token = {
    image: string | StaticImageData
    address: string
    name: string
    priceFeed: string
    slug: string
}

export const Main = () => {

    const testToken1Address = deploymentsConfig["networks"]["goerli"]["test_token_1"]
    const testToken2Address = deploymentsConfig["networks"]["goerli"]["test_token_2"]
    const testToken3Address = deploymentsConfig["networks"]["goerli"]["test_token_3"]

    const priceFeed = deploymentsConfig["networks"]["goerli"]["price_feed"]

    const supportedTokens: Array<Token> = [
        {
            image: eth,
            address: testToken1Address,
            name: "Test Token 1",
            priceFeed: priceFeed,
            slug: "eth",
        },
        {
            image: dai,
            address: testToken2Address,
            name: "Test Token 2",
            priceFeed: priceFeed,
            slug: "dai",
        },
        {
            image: usdc,
            address: testToken3Address,
            name: "Test Token 3",
            priceFeed: priceFeed,
            slug: "usdc",
        },
    ]


    return { supportedTokens }

}

