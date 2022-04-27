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
import time

signer1 = Signer(123456789987654321)
signer2 = Signer(987654321123456789)

VOTE_CERTIFICATE_CONTRACT_FILE = os.path.join("contracts/governance", "VotingCertificate.cairo")
GOVERNOR_CONTRACT_FILE = os.path.join("contracts/governance", "Governor.cairo")
ZODIAC_RELAYER_CONTRACT_FILE = os.path.join("contracts/governance/execution", "zodiac_relayer.cairo")
TARGET_CONTRACT_FILE = os.path.join("contracts/governance/execution", "Target.cairo")
BASIC_VOTING_STRATEGY_CONTRACT_FILE = os.path.join("contracts/governance/strategies", "vanilla.cairo")
SHARE_VOTING_STRATEGY_CONTRACT_FILE = os.path.join("contracts/governance/strategies", "ERC721_voting.cairo")
AUTHENTICATOR_CONTRACT_FILE = os.path.join("contracts/governance/authenticator", "authenticator.cairo")

TEST_SHARE = to_uint(100)
TEST_FUND = 1

VOTING_DELAY = 0
VOTING_DURATION = 20
PROPOSAL_THRESHOLD = to_uint(1)
CONTROLLER = 1337

METADATA_URI = str_to_short_str_array("This is a test.")
ETH_BLOCK_NUMBER = 1337
L1_EXECUTION_PARAMS = [int('0xaaaaaaaaaaaa', 0)]
TARGET_EXECUTION_PARAMS = []
TARGET_EXECUTION_HASH = to_uint(2)

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
    
    # Deploy test vote certificate
    vote_certificate = await starknet.deploy(
        source=VOTE_CERTIFICATE_CONTRACT_FILE,
        constructor_calldata=[
            str_to_felt("Vote Certificate"),
            str_to_felt("VC"),
            account1.contract_address,
        ]
    )

    # Mint a test token from the vote certificate
    await signer1.send_transaction(
        account=account1,
        to=vote_certificate.contract_address,
        selector_name="mint",
        calldata=[
            account1.contract_address,
            *TEST_SHARE,
            TEST_FUND
            ],
    )

    zodiac_relayer = await starknet.deploy(
        source=ZODIAC_RELAYER_CONTRACT_FILE,
        constructor_calldata=[]
    )

    target = await starknet.deploy(
        source=TARGET_CONTRACT_FILE,
        constructor_calldata=[]
    )

    basic_voting_strategy = await starknet.deploy(
        source=BASIC_VOTING_STRATEGY_CONTRACT_FILE,
        constructor_calldata=[]
    )

    share_voting_strategy = await starknet.deploy(
        source=SHARE_VOTING_STRATEGY_CONTRACT_FILE,
        constructor_calldata=[]
    )

    authenticator = await starknet.deploy(
        source=AUTHENTICATOR_CONTRACT_FILE,
        constructor_calldata=[]
    )

    governor = await starknet.deploy(
        source=GOVERNOR_CONTRACT_FILE,
        constructor_calldata=[
            VOTING_DELAY,
            VOTING_DURATION,
            *PROPOSAL_THRESHOLD,
            target.contract_address,
            CONTROLLER,
            1,
            share_voting_strategy.contract_address,
            1,
            authenticator.contract_address
        ],
    )

    return (
        starknet,
        account1,
        governor,
        vote_certificate,
        zodiac_relayer,
        target,
        basic_voting_strategy,
        share_voting_strategy,
        authenticator
    )

@pytest.mark.asyncio
async def test_create_proposal(contract_factory):
    """Tests creating a proposal."""
    (
        starknet,
        account1,
        governor,
        vote_certificate,
        zodiac_relayer,
        target,
        basic_voting_strategy,
        share_voting_strategy,
        authenticator
    ) = contract_factory

    VOTING_PARAMS = [vote_certificate.contract_address,TEST_FUND]

    execution_info = await authenticator.execute(
        to=governor.contract_address,
        function_selector=get_selector_from_name("propose"),
        calldata=[
            account1.contract_address,
            *TARGET_EXECUTION_HASH,
            len(METADATA_URI),
            *METADATA_URI,
            ETH_BLOCK_NUMBER,
            len(VOTING_PARAMS),
            *VOTING_PARAMS,
            len(TARGET_EXECUTION_PARAMS),
            *TARGET_EXECUTION_PARAMS
        ]
    ).invoke()

@pytest.mark.asyncio
async def test_cast_vote(contract_factory):
    """Tests cast a vote."""
    (
        starknet,
        account1,
        governor,
        vote_certificate,
        zodiac_relayer,
        target,
        basic_voting_strategy,
        share_voting_strategy,
        authenticator
    ) = contract_factory

    execution_info = await governor.get_proposal_info(
        proposal_id=1
    ).call()

    # We can't directly compare the `info` object because we don't know for sure the value of `start_block` (and hence `end_block`),
    # so we compare it element by element (except start_block and end_block for which we simply compare their difference to `VOTING_PERIOD`).
    execution_hash = execution_info.result.proposal_info.proposal.execution_hash
    assert execution_hash == TARGET_EXECUTION_HASH
    assert (execution_info.result.proposal_info.proposal.end_timestamp 
        - execution_info.result.proposal_info.proposal.start_timestamp) == 20
    _for = execution_info.result.proposal_info.power_for
    assert _for == to_uint(0)
    against = execution_info.result.proposal_info.power_against
    assert against == to_uint(0)
    abstain = execution_info.result.proposal_info.power_abstain
    assert abstain == to_uint(0)

    VOTING_PARAMS = [vote_certificate.contract_address,TEST_FUND]

    voter_address = account1.contract_address
    execution_info = await authenticator.execute(
        to=governor.contract_address,
        function_selector=get_selector_from_name("vote"),
        calldata=[
            voter_address, 
            1, 
            1, 
            len(VOTING_PARAMS),
            *VOTING_PARAMS
        ]
    ).invoke()

    execution_info = await governor.get_proposal_info(
        proposal_id=1
    ).call()

    _for = execution_info.result.proposal_info.power_for
    assert _for == to_uint(100)
    against = execution_info.result.proposal_info.power_against
    assert against == to_uint(0)
    abstain = execution_info.result.proposal_info.power_abstain
    assert abstain == to_uint(0)

@pytest.mark.asyncio
async def test_execute_proposal(contract_factory):
    """Tests executing a proposal after voting period ended."""
    (
        starknet,
        account1,
        governor,
        vote_certificate,
        zodiac_relayer,
        target,
        basic_voting_strategy,
        share_voting_strategy,
        authenticator
    ) = contract_factory

    execution_info = await authenticator.execute(
        to=governor.contract_address,
        function_selector=get_selector_from_name("finalize_proposal"),
        calldata=[
            1,
            len(TARGET_EXECUTION_PARAMS),
            *TARGET_EXECUTION_PARAMS
        ]
    ).invoke()

    execution_info = await target.get_balance().call()
    balance = execution_info.result
    assert balance == (to_uint(2),)
