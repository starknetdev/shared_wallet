"""account.cairo test file."""
import os

import pytest
from starkware.starknet.testing.starknet import Starknet
from starkware.starkware_utils.error_handling import StarkException
from utils.Signer import Signer

ACCOUNT_CONTRACT_FILE = os.path.join("contracts", "Account.cairo")
ERC20_CONTRACT_FILE = os.path.join("contracts", "ERC20.cairo")
SHARED_WALLET_CONTRACT_FILE = os.path.join("contracts", "shared_wallet.cairo")

signer = Signer(123456789)


@pytest.mark.asyncio
async def test_only_owners():
    """Test only in owners guard."""
    starknet = await Starknet.empty()
    account_contract = await starknet.deploy(
        source=ACCOUNT_CONTRACT_FILE, constructor_calldata=[signer.public_key]
    )
    erc20_contract = await starknet.deploy(
        source=ERC20_CONTRACT_FILE,
        constructor_calldata=[
            123,
            123,
            18,
            0,
            1000 * 10**18,
            account_contract.contract_address,
        ],
    )
    shared_wallet_contract = await starknet.deploy(source=SHARED_WALLET_CONTRACT_FILE)
    with pytest.raises(StarkException):
        await signer.send_transaction(
            account=account_contract,
            to=shared_wallet_contract.contract_address,
            selector_name="deposit",
            calldata=[10],
        )

    await signer.send_transaction(
        account=account_contract,
        to=shared_wallet_contract.contract_address,
        selector_name="initialize_owner",
        calldata=[],
    )

    await signer.send_transaction(
        account=account_contract,
        to=shared_wallet_contract.contract_address,
        selector_name="deposit",
        calldata=[10],
    )

    execution_info = await shared_wallet_contract.get_owner_balance().call()
    assert execution_info.result == (10,)


# @pytest.mark.asyncio
# async def test_deposit_and_withdraw():
#     """Test deposit and withdraw function."""
#     starknet = await Starknet.empty()
#     account_contract = await starknet.deploy(source=CONTRACT_FILE)

#     await account_contract.initialize_owner().invoke()
#     await account_contract.deposit(amount=10).invoke()
#     await account_contract.withdraw(amount=5).invoke()

#     execution_info = await account_contract.get_owner_balance().call()
#     assert execution_info.result == (5,)

#     with pytest.raises(StarkException):
#         await account_contract.withdraw(amount=10).invoke()
