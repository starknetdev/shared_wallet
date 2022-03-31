%lang starknet
%builtins pedersen range_check_ptr

from starknet.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.storage import storage
from starkware.starknet.common.syscalls import get_caller_address

#
# Storage
#

@storage_var
func is_owner(owner_public_key: felt) -> (res: felt):
end

@storage_var
func owners_balance(owner_public_key: felt) -> (res: felt):
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
    }(owner_public_key: felt) -> (is_owner: felt):
    alloc_locals
    let (caller_address) = get_caller_address()
    let (is_owner) = is_owner.read(owner_public_key)
    return (is_owner)
end

@view
func get_owners_balance{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(owner_public_key: felt) -> (balance: felt):
    alloc_locals
    let (balance) = owners_balance.read(owner_public_key)
    return (balance)
end

#
# Guards
#

func only_in_owners{
        syscall_ptr: felt*,
    }():
    let (caller_address) = get_caller_address()
    let (is_owner) = get_is_owner(caller_address)
    with_attr error_message("Ownable: caller is not in owners")
        assert is_owner == 1
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
    only_in_owners()
    let (caller_address) = get_caller_address()
    let (old_balance) = get_owners_balance(caller_address)
    let (new_balance) = old_balance + amount
    owner_balance.write(caller_address, amount)
    return ()
end

@external
func withdraw{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(amount: felt):
    only_in_owners()
    return ()
end

@

