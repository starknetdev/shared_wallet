"""SharedWalletERC721.cairo test file."""
import asyncio
from copyreg import constructor
import os
from unittest.mock import call

import pytest
from starkware.starknet.business_logic.state.state import BlockInfo
from starkware.starknet.public.abi import get_selector_from_name
from starkware.starknet.testing.starknet import Starknet
from starkware.starkware_utils.error_handling import StarkException
from utils import str_to_felt, to_uint, str_to_short_str_array
from tests.Signer import Signer
import time

signer1 = Signer(123456789987654321)
signer2 = Signer(987654321123456789)

TEST_TOKEN_CONTRACT_FILE = os.path.join("contracts", "TestToken.cairo")
PRICE_AGGREGATOR_CONTRACT_FILE = os.path.join(
    "contracts/oracles", "MockPriceAggregator.cairo"
)
SHARE_CERTIFICATE_CONTRACT_FILE = os.path.join("contracts", "ShareCertificate.cairo")
# SHARED_WALLET_FACTORY_FILE = os.path.join(
#     "contracts/upgrades", "SharedWalletFactory.cairo"
# )
SHARED_WALLET_CONTRACT_FILE = os.path.join("contracts", "SharedWallet.cairo")
GOVERNOR_CONTRACT_FILE = os.path.join("contracts", "Governor.cairo")
SHARE_VOTING_STRATEGY_CONTRACT_FILE = os.path.join(
    "contracts/strategies", "ShareVoting.cairo"
)
AUTHENTICATOR_CONTRACT_FILE = os.path.join(
    "contracts/authenticator", "authenticator.cairo"
)


TOKENS = to_uint(10000 * 10**18)
ADD_AMOUNT_1 = to_uint(1 * 10**18)
ADD_AMOUNT_2 = to_uint(4000 * 10**18)

ERC20_1_price = to_uint(4000 * 10**18)
ERC20_2_price = to_uint(1 * 10**18)

# Governance parameters
VOTING_DELAY = 0
VOTING_DURATION = 20
PROPOSAL_THRESHOLD = to_uint(1)
CONTROLLER = 1337

METADATA_URI = str_to_short_str_array("This is a test.")
ETH_BLOCK_NUMBER = 1337
TARGET_EXECUTION_PARAMS = []
TARGET_EXECUTION_HASH = to_uint(0)


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

    erc20_1 = await starknet.deploy(
        source=TEST_TOKEN_CONTRACT_FILE,
        constructor_calldata=[
            str_to_felt("Test Token 1"),
            str_to_felt("TT1"),
            18,
            *TOKENS,
            account1.contract_address,
            account1.contract_address,
        ],
    )

    erc20_2 = await starknet.deploy(
        source=TEST_TOKEN_CONTRACT_FILE,
        constructor_calldata=[
            str_to_felt("Test Token 2"),
            str_to_felt("TT2"),
            18,
            *TOKENS,
            account1.contract_address,
            account1.contract_address,
        ],
    )

    # Deploy mock oracle.
    # ERC20_1 with price $4000
    # ERC20_2 with price $1

    oracle = await starknet.deploy(
        source=PRICE_AGGREGATOR_CONTRACT_FILE,
        constructor_calldata=[
            2,
            erc20_1.contract_address,
            erc20_2.contract_address,
            2,
            *ERC20_1_price,
            *ERC20_2_price,
        ],
    )

    # Deploy token to distribute shares

    share_certificate = await starknet.deploy(
        source=SHARE_CERTIFICATE_CONTRACT_FILE,
        constructor_calldata=[
            str_to_felt("Share Certificate"),
            str_to_felt("SC"),
            account1.contract_address,
        ],
    )

    # Deploy the shared wallet contract.
    # It has a 50:50 ERC20_1 and ERC20_2 composition

    # shared_wallet_factory = await starknet.deploy(
    #     source=SHARED_WALLET_FACTORY_FILE,
    #     constructor_calldata=[
    #         account1.contract_address,
    #         share_certificate.contract_address,
    #     ],
    # )

    # await signer1.send_transaction(
    #     account=account1,
    #     to=shared_wallet_factory.contract_address,
    #     selector_name="create_wallet",
    #     calldata=[
    #         2,
    #         account1.contract_address,
    #         account2.contract_address,
    #         2,
    #         erc20_1.contract_address,
    #         erc20_2.contract_address,
    #         2,
    #         1,
    #         1,
    #         oracle.contract_address,
    #     ],
    # )

    shared_wallet = await starknet.deploy(
        source=SHARED_WALLET_CONTRACT_FILE,
        constructor_calldata=[
            2,
            account1.contract_address,
            account2.contract_address,
            2,
            erc20_1.contract_address,
            erc20_2.contract_address,
            2,
            1,
            1,
            oracle.contract_address,
            share_certificate.contract_address,
        ],
    )

    share_voting_strategy = await starknet.deploy(
        source=SHARE_VOTING_STRATEGY_CONTRACT_FILE, constructor_calldata=[]
    )

    authenticator = await starknet.deploy(
        source=AUTHENTICATOR_CONTRACT_FILE, constructor_calldata=[]
    )

    governor = await starknet.deploy(
        source=GOVERNOR_CONTRACT_FILE,
        constructor_calldata=[
            VOTING_DELAY,
            VOTING_DURATION,
            *PROPOSAL_THRESHOLD,
            shared_wallet.contract_address,
            CONTROLLER,
            1,
            share_voting_strategy.contract_address,
            1,
            authenticator.contract_address,
        ],
    )

    # Transfer ownership of share token to the shared wallet

    await signer1.send_transaction(
        account=account1,
        to=share_certificate.contract_address,
        selector_name="transfer_ownership",
        calldata=[shared_wallet.contract_address],
    )

    return (
        starknet,
        account1,
        account2,
        erc20_1,
        erc20_2,
        oracle,
        share_certificate,
        shared_wallet,
        governor,
        authenticator,
    )


@pytest.mark.asyncio
async def test_deployed_shared_wallet(contract_factory):
    """Tests the parameters of the deloyed shared wallet contract."""
    (
        starknet,
        account1,
        account2,
        erc20_1,
        erc20_2,
        oracle,
        share_certificate,
        shared_wallet,
        governor,
        authenticator,
    ) = contract_factory

    execution_info = await shared_wallet.get_owners().call()
    assert execution_info.result.owners == [
        account1.contract_address,
        account2.contract_address,
    ]

    execution_info = await shared_wallet.get_tokens().call()
    assert execution_info.result.tokens == [
        erc20_1.contract_address,
        erc20_2.contract_address,
    ]


@pytest.mark.asyncio
async def test_oracle(contract_factory):
    """Test oracle functions."""
    (
        starknet,
        account1,
        account2,
        erc20_1,
        erc20_2,
        oracle,
        share_certificate,
        shared_wallet,
        governor,
        authenticator,
    ) = contract_factory

    execution_info = await oracle.get_data(erc20_1.contract_address).call()
    assert execution_info.result == (ERC20_1_price, 18)

    execution_info = await oracle.get_data(erc20_2.contract_address).call()
    assert execution_info.result == (ERC20_2_price, 18)


@pytest.mark.asyncio
async def test_add_owner(contract_factory):
    """Test add owners of shared wallet."""
    (
        starknet,
        account1,
        account2,
        erc20_1,
        erc20_2,
        oracle,
        share_certificate,
        shared_wallet,
        governor,
        authenticator,
    ) = contract_factory

    # Deploy new account with new signer
    signer3 = Signer(12121212121212)
    account3 = await starknet.deploy(
        "openzeppelin/account/Account.cairo",
        constructor_calldata=[signer3.public_key],
    )

    await signer1.send_transaction(
        account=account1,
        to=shared_wallet.contract_address,
        selector_name="add_owners",
        calldata=[1, account3.contract_address],
    )

    execution_info = await shared_wallet.get_is_owner(account3.contract_address).call()
    assert execution_info.result == (1,)


@pytest.mark.asyncio
async def test_add_funds(contract_factory):
    """Test add funds to shared wallet."""
    (
        starknet,
        account1,
        account2,
        erc20_1,
        erc20_2,
        oracle,
        share_certificate,
        shared_wallet,
        governor,
        authenticator,
    ) = contract_factory

    # When depositing funds

    await signer1.send_transaction(
        account=account1,
        to=erc20_1.contract_address,
        selector_name="approve",
        calldata=[shared_wallet.contract_address, *ADD_AMOUNT_1],
    )

    await signer1.send_transaction(
        account=account1,
        to=erc20_2.contract_address,
        selector_name="approve",
        calldata=[shared_wallet.contract_address, *ADD_AMOUNT_2],
    )

    await signer1.send_transaction(
        account=account1,
        to=shared_wallet.contract_address,
        selector_name="add_funds",
        calldata=[
            2,
            erc20_1.contract_address,
            erc20_2.contract_address,
            2,
            *ADD_AMOUNT_1,
            *ADD_AMOUNT_2,
        ],
    )

    execution_info = await erc20_1.balanceOf(shared_wallet.contract_address).call()
    assert execution_info.result == (ADD_AMOUNT_1,)

    execution_info = await erc20_2.balanceOf(shared_wallet.contract_address).call()
    assert execution_info.result == (ADD_AMOUNT_2,)

    execution_info = await share_certificate.get_certificate_id(
        account1.contract_address, shared_wallet.contract_address
    ).call()
    assert execution_info.result == (to_uint(1),)

    execution_info = await share_certificate.get_shares(to_uint(1)).call()
    assert execution_info.result == (to_uint(4000 * 10**18),)

    await signer1.send_transaction(
        account=account1,
        to=erc20_1.contract_address,
        selector_name="approve",
        calldata=[shared_wallet.contract_address, *ADD_AMOUNT_1],
    )

    await signer1.send_transaction(
        account=account1,
        to=erc20_2.contract_address,
        selector_name="approve",
        calldata=[shared_wallet.contract_address, *ADD_AMOUNT_2],
    )

    await signer1.send_transaction(
        account=account1,
        to=shared_wallet.contract_address,
        selector_name="add_funds",
        calldata=[
            2,
            erc20_1.contract_address,
            erc20_2.contract_address,
            2,
            *ADD_AMOUNT_1,
            *ADD_AMOUNT_2,
        ],
    )

    execution_info = await share_certificate.get_shares(to_uint(1)).call()
    assert execution_info.result == (to_uint(8000 * 10**18),)


@pytest.mark.asyncio
async def test_remove_funds(contract_factory):
    """Test remove funds to shared wallet."""
    (
        starknet,
        account1,
        account2,
        erc20_1,
        erc20_2,
        oracle,
        share_certificate,
        shared_wallet,
        governor,
        authenticator,
    ) = contract_factory

    await signer1.send_transaction(
        account=account1,
        to=shared_wallet.contract_address,
        selector_name="remove_funds",
        calldata=[*to_uint(4000 * 10**18)],
    )

    execution_info = await share_certificate.get_certificate_id(
        account1.contract_address, shared_wallet.contract_address
    ).call()
    assert execution_info.result == (to_uint(1),)

    execution_info = await share_certificate.get_shares(to_uint(1)).call()
    assert execution_info.result == (to_uint(4000 * 10**18),)

    execution_info = await erc20_1.balanceOf(shared_wallet.contract_address).call()
    assert execution_info.result == (to_uint(1 * 10**18),)

    execution_info = await erc20_2.balanceOf(shared_wallet.contract_address).call()
    assert execution_info.result == (to_uint(4000 * 10**18),)


@pytest.mark.asyncio
async def test_proposal(contract_factory):
    """Test governance proposal on shared wallet."""
    (
        starknet,
        account1,
        account2,
        erc20_1,
        erc20_2,
        oracle,
        share_certificate,
        shared_wallet,
        governor,
        authenticator,
    ) = contract_factory

    execution_info = await share_certificate.get_fund(token_id=to_uint(1)).call()
    fund = execution_info.result.fund

    VOTING_PARAMS = [share_certificate.contract_address, fund]

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
            *TARGET_EXECUTION_PARAMS,
        ],
    ).invoke()


@pytest.mark.asyncio
async def test_cast_vote(contract_factory):
    """Test casting a governance vote on proposal."""
    (
        starknet,
        account1,
        account2,
        erc20_1,
        erc20_2,
        oracle,
        share_certificate,
        shared_wallet,
        governor,
        authenticator,
    ) = contract_factory

    execution_info = await governor.get_proposal_info(proposal_id=1).call()

    # We can't directly compare the `info` object because we don't know for sure the value of `start_block` (and hence `end_block`),
    # so we compare it element by element (except start_block and end_block for which we simply compare their difference to `VOTING_PERIOD`).
    execution_hash = execution_info.result.proposal_info.proposal.execution_hash
    assert execution_hash == TARGET_EXECUTION_HASH
    assert (
        execution_info.result.proposal_info.proposal.end_timestamp
        - execution_info.result.proposal_info.proposal.start_timestamp
    ) == 20
    _for = execution_info.result.proposal_info.power_for
    assert _for == to_uint(0)
    against = execution_info.result.proposal_info.power_against
    assert against == to_uint(0)
    abstain = execution_info.result.proposal_info.power_abstain
    assert abstain == to_uint(0)

    execution_info = await share_certificate.get_fund(token_id=to_uint(1)).call()
    fund = execution_info.result.fund

    VOTING_PARAMS = [share_certificate.contract_address, fund]

    voter_address = account1.contract_address
    execution_info = await authenticator.execute(
        to=governor.contract_address,
        function_selector=get_selector_from_name("vote"),
        calldata=[voter_address, 1, 1, len(VOTING_PARAMS), *VOTING_PARAMS],
    ).invoke()

    execution_info = await governor.get_proposal_info(proposal_id=1).call()

    _for = execution_info.result.proposal_info.power_for
    assert _for == to_uint(4000 * 10**18)
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
        account2,
        erc20_1,
        erc20_2,
        oracle,
        share_certificate,
        shared_wallet,
        governor,
        authenticator,
    ) = contract_factory

    set_block_timestamp(starknet.state, int(time.time() + 20), 11)

    execution_info = await authenticator.execute(
        to=governor.contract_address,
        function_selector=get_selector_from_name("finalize_proposal"),
        calldata=[1, len(TARGET_EXECUTION_PARAMS), *TARGET_EXECUTION_PARAMS],
    ).invoke()


# adjusting block number
def set_block_number(self, block_number, gas_price):
    self.state.block_info = BlockInfo(
        block_number, self.state.block_info.block_timestamp, gas_price
    )


# adjusting block number
def set_block_timestamp(self, block_timestamp, gas_price):
    self.state.block_info = BlockInfo(
        self.state.block_info.block_number, block_timestamp, gas_price
    )
