%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from contracts.ERC721_shares.SharedWalletERC721 import shared_wallet_initializer

from openzeppelin.access.ownable import (
    Ownable_initializer,
    Ownable_only_owner
)

#
# Storage variables
#

@storage_var
func shared_wallets(index: felt) -> (res: felt):
end

@storage_var
func _share_certificate() -> (res: felt):
end

#
# Constructor
#

@constructor
func constructor{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }(
        owner : felt,
        share_certificate : felt
    ):
    _share_certificate.write(share_certificate)
    Ownable_initializer(owner)
    return ()
end

#
# Actions
#

@external
func create_wallet{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }(
        owners_len : felt,
        owners : felt*,
        tokens_len : felt,
        tokens : felt*,
        token_weights_len : felt,
        token_weights : felt*,
        oracle : felt
    ):
    Ownable_only_owner()
    let (share_certificate) =  _share_certificate.read()
    shared_wallet_initializer(
        owners_len,
        owners,
        tokens_len,
        tokens,
        token_weights_len,
        token_weights,
        oracle,
        share_certificate
    )
    return ()
end