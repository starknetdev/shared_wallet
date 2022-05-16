from ape import accounts, project
from utils import str_to_felt, Signer, to_uint

signer = Signer(123456789987654321)


def test_add_funds(account, fund_tokens, share_certificate, shared_wallet):
    erc20_1, erc20_2, _ = fund_tokens
    account.erc20_1.approve(shared_wallet, to_uint(10))
    account.erc20_2.approve(shared_wallet, to_uint(10))
    account.shared_wallet.add_funds(2, erc20_1, erc20_2, 2, to_uint(10), to_uint(10))
    execution_info = share_certificate.get_shares(to_uint(1))
    print(execution_info)


# def test_revert_non_holder(token_gated_account, test_nft):
#     token_gated_account
