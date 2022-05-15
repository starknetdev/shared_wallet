import pytest
from ape import accounts, project
from utils import str_to_felt, to_uint, Signer

TOKENS = to_uint(10000 * 10**18)

ERC20_1_price = to_uint(4000 * 10**18)
ERC20_2_price = to_uint(1 * 10**18)
ERC20_3_price = to_uint(200 * 10**18)

signer = Signer(123456789987654321)

@pytest.fixture(scope="session")
def account():
    container = accounts.containers["starknet"]
    return container.deploy_account("Test Account")

@pytest.fixture(scope="session")
def account1():
    container = accounts.containers["starknet"]
    return container.deploy_account("Test Account 1")

@pytest.fixture(scope="session")
def share_certificate(account):
    return project.ShareCerficate.deploy(
        str_to_felt("Test Share Certificate"),
        str_to_felt("TSC"),
        account
    )

@pytest.fixture(scope="session")
def fund_tokens(account):
    erc20_1 = project.TestToken.deploy(
        str_to_felt("Test Token 1"),
        str_to_felt("TT1"),
        18,
        TOKENS,
        account,
        account,
    )
    erc20_2 = project.TestToken.deploy(
        str_to_felt("Test Token 2"),
        str_to_felt("TT2"),
        18,
        *TOKENS,
        account,
        account,
    )
    erc20_3 = project.TestToken.deploy(
        str_to_felt("Test Token 3"),
        str_to_felt("TT3"),
        18,
        *TOKENS,
        account,
        account,
    )
    return erc20_1, erc20_2, erc20_3

@pytest.fixture(scope="session")
def oracle(fund_tokens):
    return project.MockPriceAggregator.deploy(
        3,
        *fund_tokens,
        3,
        *ERC20_1_price,
        *ERC20_2_price,
        *ERC20_3_price
    )

@pytest.fixture(scope="session")
def shared_wallet(account, account1, fund_tokens, oracle, share_certificate):
    erc20_1, erc20_2, _ = fund_tokens
    return project.SharedWallet.deploy(
        2,
        account,
        account1,
        2,
        erc20_1,
        erc20_2,
        2,
        1,
        1,
        oracle,
        share_certificate
    )
