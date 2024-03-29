%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_le, assert_lt
from starkware.starknet.common.syscalls import call_contract, get_caller_address
from starkware.cairo.common.uint256 import (
    Uint256,
    uint256_add,
    uint256_sub
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

from openzeppelin.introspection.ERC165 import ERC165_supports_interface

from openzeppelin.access.ownable import (
    Ownable_initializer,
    Ownable_only_owner,
    Ownable_transfer_ownership
)

#
# Structs
#

struct CertificateData:
    member owner: felt
    member share: Uint256
    member fund: felt
end

#
# Storage variables
#

@storage_var
func _certificate_id_count() -> (res : Uint256):
end

@storage_var
func _certificate_id(owner : felt, fund : felt) -> (token_id : Uint256):
end

@storage_var
func _certificate_data(token_id : Uint256) -> (res: CertificateData):
end

@storage_var
func _total_shares(fund : felt) -> (res : Uint256):
end

#
# Getters
#

@view
func supportsInterface{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(interfaceId: felt) -> (success: felt):
    let (success) = ERC165_supports_interface(interfaceId)
    return (success)
end

@view
func name{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (name: felt):
    let (name) = ERC721_name()
    return (name)
end

@view
func symbol{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (symbol: felt):
    let (symbol) = ERC721_symbol()
    return (symbol)
end

@view
func balanceOf{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(owner: felt) -> (balance: Uint256):
    let (balance: Uint256) = ERC721_balanceOf(owner)
    return (balance)
end

@view
func ownerOf{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(tokenId: Uint256) -> (owner: felt):
    let (owner: felt) = ERC721_ownerOf(tokenId)
    return (owner)
end

@view
func getApproved{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(tokenId: Uint256) -> (approved: felt):
    let (approved: felt) = ERC721_getApproved(tokenId)
    return (approved)
end

@view
func isApprovedForAll{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(owner: felt, operator: felt) -> (isApproved: felt):
    let (isApproved: felt) = ERC721_isApprovedForAll(owner, operator)
    return (isApproved)
end

@view
func tokenURI{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*, 
        range_check_ptr
    }(tokenId: Uint256) -> (tokenURI: felt):
    let (tokenURI: felt) = ERC721_tokenURI(tokenId)
    return (tokenURI)
end

@view
func get_certificate_id{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(owner : felt, fund : felt) -> (token_id : Uint256):
   let (value) =  _certificate_id.read(owner, fund)
   return (value)
end

@view
func get_certificate_data{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(token_id : Uint256) -> (certificate_data : CertificateData):
    let (certificate_data) = _certificate_data.read(token_id)       
    return (certificate_data)
end

@view
func get_shares{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(token_id : Uint256) -> (share : Uint256):
    let (certificate_data) = _certificate_data.read(token_id=token_id)
    let share = certificate_data.share
    return (share)
end

@view 
func get_total_shares{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(fund : felt) -> (total_shares : Uint256):
    let (total_shares) = _total_shares.read(fund)
    return (total_shares)
end

@view 
func get_fund{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(token_id : Uint256) -> (fund : felt):
    let (certificate_data) = _certificate_data.read(token_id)
    let fund = certificate_data.fund
    return (fund)
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
func approve{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(to: felt, tokenId: Uint256):
    ERC721_approve(to, tokenId)
    return ()
end

@external
func setApprovalForAll{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*, 
        range_check_ptr
    }(operator: felt, approved: felt):
    ERC721_setApprovalForAll(operator, approved)
    return ()
end

@external
func transferFrom{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        from_: felt, 
        to: felt, 
        tokenId: Uint256
    ):
    ERC721_transferFrom(from_, to, tokenId)
    return ()
end

@external
func safeTransferFrom{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        from_: felt, 
        to: felt, 
        tokenId: Uint256,
        data_len: felt, 
        data: felt*
    ):
    ERC721_safeTransferFrom(from_, to, tokenId, data_len, data)
    return ()
end

@external
func setTokenURI{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(tokenId: Uint256, tokenURI: felt):
    Ownable_only_owner()
    ERC721_setTokenURI(tokenId, tokenURI)
    return ()
end

@external
func transfer_ownership{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(new_owner: felt):
    Ownable_transfer_ownership(new_owner)
    return ()
end

@external
func mint{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        owner: felt,
        share: Uint256,
        fund: felt
    ):
    Ownable_only_owner()
    let (certificate_id) = _certificate_id_count.read()
    let (new_certificate_id, _) = uint256_add(certificate_id,Uint256(1,0))
    let (caller_address) = get_caller_address()
    _certificate_id.write(owner, fund, new_certificate_id)
    let data = CertificateData(
        owner=owner,
        share=share,
        fund=fund
    )
    _certificate_data.write(new_certificate_id, data)
    let (current_total_shares) = _total_shares.read(fund)
    let (new_total_shares, _) = uint256_add(current_total_shares, share)
    _total_shares.write(fund, new_total_shares)
    ERC721_mint(owner, new_certificate_id)
    return ()
end

@external
func burn{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        token_id : Uint256
    ):
    Ownable_only_owner()
    let (certificate_data) = _certificate_data.read(token_id)
    let current_shares = certificate_data.share
    # Reset certificate data struct
    let data = CertificateData(
        owner=0,
        share=Uint256(0,0),
        fund=0
    )
    _certificate_data.write(token_id, data)
    let (current_total_shares) = _total_shares.read(certificate_data.fund)
    let (new_total_shares) = uint256_sub(current_total_shares, current_shares)
    _total_shares.write(certificate_data.fund, new_total_shares)
    ERC721_burn(token_id)
    return ()
end

@external
func increase_shares{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        token_id : Uint256,
        amount : Uint256
    ):
    Ownable_only_owner()
    let (certificate_data) = _certificate_data.read(token_id)
    let (current_shares) = get_shares(token_id)
    let (new_share, _) = uint256_add(current_shares, amount)
    let new_data = CertificateData(
        owner=certificate_data.owner,
        share=new_share,
        fund=certificate_data.fund
    )
    _certificate_data.write(token_id, new_data)
    let (current_total_shares) = _total_shares.read(certificate_data.fund)
    let (new_total_shares, _) = uint256_add(current_total_shares, amount)
    _total_shares.write(certificate_data.fund, new_total_shares)
    return ()
end

@external
func decrease_shares{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        token_id : Uint256,
        amount : Uint256
    ):
    Ownable_only_owner()
    let (current_shares) = get_shares(token_id)
    let (new_share) = uint256_sub(current_shares, amount)
    let (certificate_data) = _certificate_data.read(token_id)
    let new_data = CertificateData(
        owner=certificate_data.owner,
        share=new_share,
        fund=certificate_data.fund
    )
    _certificate_data.write(token_id, new_data)
    let (current_total_shares) = _total_shares.read(certificate_data.fund)
    let (new_total_shares) = uint256_sub(current_total_shares, amount)
    _total_shares.write(certificate_data.fund, new_total_shares)
    return ()
end
