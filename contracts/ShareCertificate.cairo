%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_le, assert_lt
from starkware.starknet.common.syscalls import call_contract, get_caller_address
from starkware.cairo.common.uint256 import (
    Uint256,
    uint256_add
)

from contracts.utils.constants import FALSE, TRUE

from openzeppelin.token.erc721.library import (
    ERC721_name,
    ERC721_symbol,
    ERC721_balanceOf,
    ERC721_ownerOf,
    ERC721_getApproved,
    ERC721_isApprovedForAll,
    ERC721_tokenURI,

    ERC721_initializer,
    ERC721_approve, 
    ERC721_setApprovalForAll, 
    ERC721_transferFrom,
    ERC721_safeTransferFrom,
    ERC721_mint,
    ERC721_burn,
    ERC721_only_token_owner,
    ERC721_setTokenURI
)

from openzeppelin.access.ownable import (
    Ownable_initializer,
    Ownable_only_owner
)

#
# Structs
#

struct CertificateData:
    member token_id: Uint256
    member share: Uint256
    member owner: felt
end

#
# Storage variables
#

@storage_var
func _certificate_id_count() -> (res: Uint256):
end

@storage_var
func _certificate_id(owner: felt) -> (token_id: Uint256):
end

@storage_var
func _certificate_data(token_id: Uint256) -> (res: CertificateData):
end

#
# Constructor
#

@constructor
func constructor{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        name: felt,
        symbol: felt,
        owner: felt
    ):
    ERC721_initializer(name, symbol)
    Ownable_initializer(owner)
    return ()
end

#
# External
#

@external
func mint{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        owner: felt,
        share: Uint256
    ):
    let (certificate_id) = _certificate_id_count.read()
    let (new_certificate_id, _) = uint256_add(certificate_id,Uint256(1,0))
    let data = CertificateData(
        token_id=new_certificate_id,
        share=share,
        owner=owner
    )
    _certificate_data.write(new_certificate_id, data)
    ERC721_mint(owner, new_certificate_id)
    return ()
end

@external
func burn{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(owner: felt):
    let (token_id) = _certificate_id.read(owner)
    ERC721_burn(token_id)
    return ()
end
