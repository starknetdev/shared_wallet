%lang starknet
%builtins pedersen range_check

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
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
func owner_balance(owner_public_key: felt) -> (res: felt):
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
    }(owner_public_key: felt) -> (balance: felt):
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
    }(amount: felt):
    alloc_locals
    only_in_owners()
    let (caller_address) = get_caller_address()
    let (local old_balance) = owner_balance.read(caller_address)
    assert_not_zero(amount)
    owner_balance.write(caller_address, old_balance + amount)
    let (contract_address) = get_contract_address()
    let transfer_amount: Uint256 = Uint256(amount*1000000000000000000,0)
    IERC20.transferFrom(contract_address=contract_address, sender=caller_address, recipient=contract_address, amount=transfer_amount)
    return ()
end

@external
func withdraw{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(amount: felt):
    alloc_locals
    only_in_owners()
    let (caller_address) = get_caller_address()
    let (local old_balance) = owner_balance.read(caller_address)
    assert_not_zero(amount)
    assert_le(amount, old_balance)
    owner_balance.write(caller_address, old_balance - amount)
    let transfer_amount: Uint256 = Uint256(amount*1000000000000000000,0)
    let (contract_address) = get_contract_address()
    IERC20.transfer(contract_address=contract_address, recipient=caller_address, amount=transfer_amount)
    return ()
end