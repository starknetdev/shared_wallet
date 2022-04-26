"""Governor.cairo test file."""
import asyncio
from copyreg import constructor
import os
from unittest.mock import call

import pytest
from starkware.starknet.public.abi import get_selector_from_name
from starkware.starknet.testing.starknet import Starknet
from starkware.starkware_utils.error_handling import StarkException
from tests.utils import str_to_felt, to_uint, str_to_short_str_array
from tests.Signer import Signer

signer1 = Signer(123456789987654321)
signer2 = Signer(987654321123456789)

GOVERNOR_CONTRACT_FILE = os.path.join("contracts/governance", "Governor.cairo")
ZODIAC_RELAYER_CONTRACT_FILE = os.path.join("contracts/governance/execution", "zodiac_relayer.cairo")
VOTING_STRATEGY_CONTRACT_FILE = os.path.join("contracts/governance/strategies", "vanilla.cairo")
AUTHENTICATOR_CONTRACT_FILE = os.path.join("contracts/governance/authenticator", "authenticator.cairo")

CONTROLLER = 1337

METADATA_URI = str_to_short_str_array("This is a test.")
ETH_BLOCK_NUMBER = 1337
VOTING_PARAMS = []
EXECUTION_PARAMS = [int('0xaaaaaaaaaaaa', 0)]

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

    zodiac_relayer = await starknet.deploy(
        source=ZODIAC_RELAYER_CONTRACT_FILE,
        constructor_calldata=[]
    )

    voting_strategy = await starknet.deploy(
        source=VOTING_STRATEGY_CONTRACT_FILE,
        constructor_calldata=[]
    )

    authenticator = await starknet.deploy(
        source=AUTHENTICATOR_CONTRACT_FILE,
        constructor_calldata=[]
    )

    governor = await starknet.deploy(
        source=GOVERNOR_CONTRACT_FILE,
        constructor_calldata=[
            0,
            20,
            *to_uint(1),
            zodiac_relayer.contract_address,
            CONTROLLER,
            1,
            voting_strategy.contract_address,
            1,
            authenticator.contract_address
        ],
    )

    return (
        starknet,
        account1,
        governor,
        zodiac_relayer,
        voting_strategy,
        authenticator
    )

@pytest.mark.asyncio
async def test_create_proposal(contract_factory):
    """Tests creating a proposal."""
    (
        starknet,
        account1,
        governor,
        zodiac_relayer,
        voting_strategy,
        authenticator
    ) = contract_factory

    execution_info = await authenticator.execute(
        to=governor.contract_address,
        function_selector=get_selector_from_name("propose"),
        calldata=[
            account1.contract_address,
            1,
            2,
            len(METADATA_URI),
            *METADATA_URI,
            ETH_BLOCK_NUMBER,
            len(VOTING_PARAMS),
            *VOTING_PARAMS,
            len(EXECUTION_PARAMS),
            *EXECUTION_PARAMS
        ]
    ).invoke()

@pytest.mark.asyncio
async def test_cast_vote(contract_factory):
    """Tests cast a vote."""
    (
        starknet,
        account1,
        governor,
        zodiac_relayer,
        voting_strategy,
        authenticator
    ) = contract_factory

    execution_info = await governor.get_proposal_info(
        proposal_id=1
    ).call()

    print(execution_info)

    # We can't directly compare the `info` object because we don't know for sure the value of `start_block` (and hence `end_block`),
    # so we compare it element by element (except start_block and end_block for which we simply compare their difference to `VOTING_PERIOD`).
    execution_hash = execution_info.result.proposal.execution_hash
    assert execution_hash == (1,2)
    assert (execution_info.result.proposal.end_timestamp 
        - execution_info.result.proposal.start_timestamp) == 20
    _for = execution_info.result.power_for
    assert _for == 0
    against = execution_info.result.power_against
    assert against == 0
    abstain = execution_info.result.power_abstain
    assert abstain == 0

    voter_address = account1.contract_address
    execution_info = await authenticator.execute(
        to=governor.contract_address,
        function_selector=get_selector_from_name("vote"),
        calldata=[
            voter_address, 1, 1, len(VOTING_PARAMS)
        ]
    )

    execution_info = await governor.get_proposal_info(
        proposal_id=1
    ).call()

    _for = execution_info.result.power_for
    assert _for == 1
    against = execution_info.result.power_against
    assert against == 0
    abstain = execution_info.result.power_abstain
    assert abstain == 0