"""account.cairo test file."""
import os

import pytest
from starkware.starknet.testing.starknet import Starknet

CONTRACT_FILE = os.path.join("contracts", "Account.cairo")

@pytest.mark.asyncio
async def test_deposit():
    """Test deposit function."""
    starknet = await Starknet.empty()
    account_contract = await starknet.deploy(
        source = CONTRACT_FILE
    )
    await account_contract.deposit(amount=10).invoke()

    execution_info = await account_contract.get_owners_balance().call()
    assert execution_info.result == (10,)