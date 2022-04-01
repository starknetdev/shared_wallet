"""account.cairo test file."""
import asyncio
import os

import pytest
from starkware.starknet.testing.starknet import Starknet
from starkware.starkware_utils.error_handling import StarkException
from tests.utils import Signer, str_to_felt, to_uint

SHARED_WALLET_CONTRACT_FILE = os.path.join("contracts", "shared_wallet.cairo")

signer = Signer(123456789987654321)

TOKENS = to_uint(500)


@pytest.fixture(scope="module")
def event_loop():
    return asyncio.new_event_loop()


@pytest.fixture(scope="module")
async def contract_factory():
    starknet = await Starknet.empty()
    account1 = await starknet.deploy(
        "openzeppelin/account/Account.cairo", constructor_calldata=[signer.public_key]
    )
    account2 = await starknet.deploy(
        "openzeppelin/account/Account.cairo", constructor_calldata=[signer.public_key]
    )
    erc20 = await starknet.deploy(
        "openzeppelin/token/erc20/ERC20_Mintable.cairo",
        constructor_calldata=[
            str_to_felt("Test Token"),
            str_to_felt("TTKN"),
            18,
            *TOKENS,
            account1.contract_address,
            account1.contract_address,
        ],
    )

    # Mint tokens to account 2
    await signer.send_transaction(
        account=account1,
        to=erc20.contract_address,
        selector_name="mint",
        calldata=[account2.contract_address, *TOKENS],
    )

    contract = await starknet.deploy(source=SHARED_WALLET_CONTRACT_FILE)
    return starknet, contract, account1, account2, erc20


@pytest.mark.asyncio
async def test_only_owners(contract_factory):
    """Test only in owners guard."""
    starknet, contract, account1, account2, erc20 = contract_factory
    with pytest.raises(StarkException):
        await signer.send_transaction(
            account=account1,
            to=contract.contract_address,
            selector_name="deposit",
            calldata=[10],
        )

    await signer.send_transaction(
        account=account1,
        to=contract.contract_address,
        selector_name="initialize_owner",
        calldata=[],
    )

    await signer.send_transaction(
        account=account1,
        to=contract.contract_address,
        selector_name="deposit",
        calldata=[10],
    )

    execution_info = await contract.get_owner_balance().call()
    assert execution_info.result == (10,)


@pytest.mark.asyncio
async def test_deposit_and_withdraw():
    """Test deposit and withdraw function."""
    starknet, contract, account1, account2, erc20 = contract_factory
    starknet = await Starknet.empty()
    contract = await starknet.deploy(source=SHARED_WALLET_CONTRACT_FILE)

    await signer.send_transaction(
        account=account1,
        to=contract.contract_address,
        selector_name="initialize_owner",
        calldata=[],
    )

    await signer.send_transaction(
        account=account2,
        to=contract.contract_address,
        selector_name="initialize_owner",
        calldata=[],
    )

    await signer.send_transaction(
        account=account1,
        to=contract.contract_address,
        selector_name="deposit",
        calldata=[10],
    )

    await signer.send_transaction(
        account=account2,
        to=contract.contract_address,
        selector_name="deposit",
        calldata=[10],
    )

    await signer.send_transaction(
        account=account1,
        to=contract.contract_address,
        selector_name="withdraw",
        calldata=[5],
    )

    execution_info = await contract.get_owner_balance(account1.contract_address).call()
    assert execution_info.result == (5,)

    execution_info = await contract.get_owner_balance(account2.contract_address).call()
    assert execution_info.result == (10,)

    with pytest.raises(StarkException):
        await signer.send_transaction(
            account=account1,
            to=contract.contract_address,
            selector_name="withdraw",
            calldata=[10],
        )
