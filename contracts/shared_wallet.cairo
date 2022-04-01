%lang starknet
%builtins pedersen range_check

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import (
    Uint256,
    uint256_add,
    uint256_sub,
    uint256_le,
    uint256_lt,
)
from starkware.cairo.common.math import assert_not_zero, assert_le
from starkware.starknet.common.syscalls import get_caller_address, get_contract_address

from openzeppelin.token.erc20.interfaces.IERC20 import IERC20

#
# Storage
#

@storage_var
func is_owner(owner_public_key: felt) -> (res: felt):
end

@storage_var
func owner_balance(owner_public_key: felt) -> (res: Uint256):
end

@storage_var
func account_nonce() -> (res: felt):
end

#
# Getters
#

@view
func get_is_owner{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(owner_public_key: felt) -> (value: felt):
    let (value) = is_owner.read(owner_public_key)
    return (value)
end

@view
func get_owner_balance{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(owner_public_key: felt) -> (balance: Uint256):
    let (balance) = owner_balance.read(owner_public_key)
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
    with_attr error_message("Ownable: caller is not in owners"):
        assert is_owner = 1
    end
    return ()
end

#
# External
#

@external
func initialize_owner{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }():
    let (caller_address) = get_caller_address()
    is_owner.write(caller_address, 1)
    return ()
end


@external
func deposit{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(amount: Uint256):
    alloc_locals
    only_in_owners()
    let (caller_address) = get_caller_address()
    let (local old_balance) = owner_balance.read(caller_address)
    let (new_amount, carry) = uint256_add(old_balance, amount)
    owner_balance.write(caller_address, new_amount)
    let (contract_address) = get_contract_address()
    IERC20.transferFrom(contract_address=contract_address, sender=caller_address, recipient=contract_address, amount=amount)
    return ()
end

@external
func withdraw{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(amount: Uint256):
    alloc_locals
    only_in_owners()
    let (caller_address) = get_caller_address()
    let (local old_balance) = owner_balance.read(caller_address)
    let (check_amount) = uint256_le(amount, old_balance)
    with_attr error_message("Withdraw amount greater than balance"): 
        assert check_amount = 1
    end
    let (new_amount) = uint256_sub(old_balance, amount)
    owner_balance.write(caller_address, new_amount)
    let (contract_address) = get_contract_address()
    IERC20.transfer(contract_address=contract_address, recipient=caller_address, amount=amount)
    return ()
end