def run(nre):
    print("Compiling test token contract…")
    nre.compile(["contracts/ERC721_shares/TestToken.cairo"])
    print("Deploying test token contracts…")
    decimals = "18"
    owner = "0"
    recipient = "0"
    params_1 = [
        str(str_to_felt("TestToken1")),
        str(str_to_felt("TTK1")),
        decimals,
        "0",
        "0",
        owner,
        recipient,
    ]
    params_2 = [
        str(str_to_felt("TestToken2")),
        str(str_to_felt("TTK2")),
        decimals,
        "0",
        "0",
        recipient,
        owner,
    ]
    params_3 = [
        str(str_to_felt("TestToken3")),
        str(str_to_felt("TTK3")),
        decimals,
        "0",
        "0",
        recipient,
        owner,
    ]
    address, abi = nre.deploy("TestToken", params_1, alias="test_token_1")
    print(f"Test Token 1: \nABI: {abi},\nContract address: {address}")
    address, abi = nre.deploy("TestToken", params_2, alias="test_token_2")
    print(f"Test Token 2: \nABI: {abi},\nContract address: {address}")
    address, abi = nre.deploy("TestToken", params_3, alias="test_token_3")
    print(f"Test Token 3: \nABI: {abi},\nContract address: {address}")


def str_to_felt(text):
    b_text = bytes(text, "ascii")
    return int.from_bytes(b_text, "big")
