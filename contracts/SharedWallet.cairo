%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_le, assert_lt
from starkware.starknet.common.syscalls import call_contract, get_caller_address, get_contract_address
from starkware.cairo.common.uint256 import (
    Uint256,
    uint256_lt,
    uint256_eq
)

from openzeppelin.token.erc20.interfaces.IERC20 import IERC20
from contracts.utils.constants import FALSE, TRUE
from contracts.interfaces.IShareCertificate import IShareCertificate

#
# Storage
#

@storage_var
func _owners_len() -> (res : felt):
end

@storage_var
func _owners(index : felt) -> (res : felt):
end

@storage_var
func _is_owner(address : felt) -> (res : felt):
end

@storage_var
func _token_reserve(token: felt) -> (res: Uint256):
end

@storage_var
func owner_balance(address: felt, token: felt) -> (res: Uint256):
end

@storage_var
func _current_nonce() -> (res: felt):
end

@storage_var
func _share_certificate() -> (res: felt):
end

#
# Getters
#

@view
func get_is_owner{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(owner_address: felt) -> (value: felt):
    let (value) = _is_owner.read(owner_address)
    return (value)
end

@view
func get_owners_len{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (owners_len : felt):
    let (owners_len) = _owners_len.read()
    return (owners_len=owners_len)
end

@view
func _get_owners{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        owners_index : felt,
        owners_len : felt,
        owners : felt*,
    ):
    if owners_index == owners_len:
        return ()
    end

    let (owner) = _owners.read(index=owners_index)
    assert owners[owners_index] = owner

    _get_owners(owners_index=owners_index + 1, owners_len=owners_len, owners=owners)
    return ()
end

@view
func get_owners{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (
        owners_len : felt,
        owners : felt*,
    ):
    alloc_locals
    let (owners) = alloc()
    let (owners_len) = _owners_len.read()
    if owners_len == 0:
        return (owners_len=owners_len, owners=owners)
    end

    # Recursively add owners from storage to the owners array
    _get_owners(owners_index=0, owners_len=owners_len, owners=owners)
    return (owners_len=owners_len, owners=owners)
end

@view
func get_balance{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(owner: felt, token: felt) -> (balance: Uint256):
    let (balance) = owner_balance.read(owner, token)
    return (balance)
end

#
# Guards
#

func only_in_owners{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }():
    let (caller_address) = get_caller_address()
    let (is_owner) = get_is_owner(caller_address)
    with_attr error_message("Ownable: caller is not an owner"):
        assert is_owner = TRUE
    end
    return ()
end

#
# Actions
#


# Deploys a single token shered wallet
@constructor
func constructor{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }(
        owners_len : felt,
        owners : felt*,
        share_certificate : felt
    ):
    _owners_len.write(value=owners_len)
    _set_owners(owners_index=0, owners_len=owners_len, owners=owners)
    _share_certificate.write(share_certificate)
    return ()
end

@external
func add_funds{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        token: felt,
        amount: Uint256
    ):
    alloc_locals
    let (local check_amount) = uint256_lt(Uint256(0,0), amount)
    with_attr error_message("SW Error: Amount must be greater than 0"):
        assert check_amount = TRUE
    end
    let (caller_address) = get_caller_address()
    let (current_balance) = owner_balance.read(caller_address, token)
    let (new_balance) = uint256_add(current_balance, amount)

    owner_balance.write(uint256_add(current_balance, amount)
    _calculate_total_share(owner=caller_address)

    let (current_reserve) = _token_reserve.read(owner, token)
    _token_reserve.write(token, uint256_add(current_reserve + amount))
    return ()
end

@external
func remove_funds{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        token: felt,
        amount: Uint256
    ):
    let (caller_address) = get_caller_address()
    let (contract_address) = get_contract_address()
    let (reserve) = _token_reserve.read(token)
    let (share

    IERC20.transfer(recipient=caller_address, amount=amount)


    return ()
end

#
# Storage Helpers
#

func _set_owners{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }(
        owners_index : felt,
        owners_len : felt,
        owners : felt*,
    ):
    if owners_index == owners_len:
        return ()
    end

     # Write the current iteration to storage
    _owners.write(index=owners_index, value=[owners])
    _is_owner.write(address=[owners], value=TRUE)

    # Recursively write the rest
    _set_owners(owners_index=owners_index + 1, owners_len=owners_len, owners=owners + 1)
    return ()
end

#
# Internals
#

func _modify_position{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(owner: felt, amount: Uint256):
    IShareCertificate.burn(contract_address=share_certificate, owner=owner)
    IShareCertificate.mint(contract_address=share_certificate, owner=caller_address, share=amount)
    return ()
end

# Calculates share without Oracles
## TODO: Create a mapping of owners tokens and append ewach time a new token is added from that owner
func _calculate_total_share{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(owner: felt):


# Calculates total share with oracles
func calculate_total_share_with_oracles{

    