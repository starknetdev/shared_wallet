"""GovernorContract.cairo test file."""
import asyncio
from copyreg import constructor
import os
from unittest.mock import call

import pytest
from starkware.starknet.public.abi import get_selector_from_name
from starkware.starknet.testing.starknet import Starknet
from starkware.starkware_utils.error_handling import StarkException
from tests.utils import str_to_felt, to_uint
from tests.Signer import Signer

signer1 = Signer(123456789987654321)
signer2 = Signer(987654321123456789)

GOVERNOR_CONTRACT_FILE = os.path.join("contracts/governance", "Governor.cairo")


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

    zodiac_relayer = await starknet.deploy()

    governor = await starknet.deploy(
        source=GOVERNOR_CONTRACT_FILE,
        constructor_calldata=[
            0,
            20,
            to_uint(1),
            to_uint(1),
            account1.contract_address,
            account1.contract_address,
        ],
    )

    return (
        starknet,
        account1,
        account2,
    )
