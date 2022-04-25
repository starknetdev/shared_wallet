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

GOVERNANCE_TOKEN_CONTRACT_FILE = os.path.join(
    "contracts/governance", "GovernanceToken.cairo"
)


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

    governance_token = await starknet.deploy(
        source=GOVERNANCE_TOKEN_CONTRACT_FILE,
        constructor_calldata=[
            str_to_felt("Test Token 1"),
            str_to_felt("TT1"),
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
    )
