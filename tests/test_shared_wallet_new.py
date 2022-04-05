"""account.cairo test file."""
import asyncio
import os

import pytest
from starkware.starknet.public.abi import get_selector_from_name
from starkware.starknet.testing.starknet import Starknet
from starkware.starkware_utils.error_handling import StarkException
from tests.utils import str_to_felt, to_uint
from tests.Signer import Signer

signer1 = Signer(123456789987654321)
signer2 = Signer(987654321123456789)


CONTRACT_FILE = os.path.join("contracts", "SharedWallet.cairo")

TOKENS = to_uint(0)
MINT_AMOUNT = to_uint(10)


@pytest.fixture(scope="module")
def event_loop():
    return asyncio.new_event_loop()


@pytest.fixture(scope="module")
async def contract_factory():
    starknet = await Starknet.empty()
    account1 = await starknet.deploy(
        "openzeppelin/account/Account.cairo",
        constructor_calldata=[signer1.public_key],
    )
    account2 = await starknet.deploy(
        "openzeppelin/account/Account.cairo",
        constructor_calldata=[signer2.public_key],
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
    shared_wallet = await starknet.deploy(
        source=CONTRACT_FILE,
        constructor_calldata=[2, account1.contract_address, account2.contract_address],
    )

    return starknet, account1, account2, erc20, shared_wallet


@pytest.mark.asyncio
async def test_initialization(contract_factory):
    """Test wallet initialized."""
    starknet, account1, account2, erc20, shared_wallet = contract_factory

    execution_info = await shared_wallet.get_is_owner(account1.contract_address).call()
    assert execution_info.result == (1,)


@pytest.mark.asyncio
async def test_only_owners(contract_factory):
    """Test only in owners guard."""
    starknet, account1, account2, erc20, shared_wallet = contract_factory

    # Transaction details
    to = erc20.contract_address
    function_selector = get_selector_from_name("mint")
    calldata_len = 2
    calldata = [shared_wallet.contract_address, *MINT_AMOUNT]

    await signer1.send_transaction(
        account=account1,
        to=shared_wallet.contract_address,
        selector_name="execute_transaction",
        calldata=[to, function_selector, calldata_len, calldata],
    )
