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
from starkware.cairo.common.math_cmp import is_not_zero
from starkware.starknet.common.syscalls import get_caller_address, get_contract_address

from openzeppelin.token.erc20.interfaces.IERC20 import IERC20

#
# Storage
#

@storage_var
func is_owner(owner_address: felt) -> (res: felt):
end

@storage_var
func owner_balance(owner_address: felt) -> (res: Uint256):
end

@storage_var
func account_nonce() -> (res: felt):
end

@storage_var
func token_address() -> (res: felt):
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
    let (value) = is_owner.read(owner_address)
    return (value)
end

@view
func get_owner_balance{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(owner_address: felt) -> (value: Uint256):
    let (value) = owner_balance.read(owner_address)
    return (value)
end

@view
func is_initialized{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (value: felt):
    let (_token_address) = token_address.read()
    let (value) = is_not_zero(_token_address)
    return (value)
end

@view 
func get_token_address{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (value: felt):
    let (value) = token_address.read()
    return (value)
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
func initialize{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(erc20_address: felt):
    let (_is_initialized) = is_initialized()
    with_attr error("Contract already initialized"):
        assert _is_initialized = 0
    end
    token_address.write(erc20_address)
    return ()
end

@external
func initialize_owner{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }():
    let (_is_initialized) = is_initialized()
    with_attr error("Contract not initialized"):
        assert _is_initialized = 1
    end
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
    let (_is_initialized) = is_initialized()
    with_attr error("Contract not initialized"):
        assert _is_initialized = 1
    end
    only_in_owners()
    let (caller_address) = get_caller_address()
    let (local old_balance) = owner_balance.read(caller_address)
    let (new_amount, carry) = uint256_add(old_balance, amount)
    owner_balance.write(caller_address, new_amount)
    let (contract_address) = get_contract_address()
    # IERC20.transferFrom(contract_address=contract_address, sender=caller_address, recipient=contract_address, amount=amount)
    let (token_address) = get_token_address()
    IERC20.transferFrom(contract_address=token_address, sender=caller_address, recipient=contract_address, amount=amount)
    return ()
end

@external
func withdraw{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(amount: Uint256):
    alloc_locals
    let (_is_initialized) = is_initialized()
    with_attr error("Contract not initialized"):
        assert _is_initialized = 1
    end
    only_in_owners()
    let (caller_address) = get_caller_address()
    let (local old_balance) = owner_balance.read(caller_address)
    let (check_amount) = uint256_le(amount, old_balance)
    with_attr error_message("Withdraw amount greater than balance"): 
        assert check_amount = 1
    end
    let (new_amount) = uint256_sub(old_balance, amount)
    owner_balance.write(caller_address, new_amount)
    # IERC20.transfer(contract_address=contract_address, recipient=caller_address, amount=amount)
    let (token_address) = get_token_address()
    IERC20.transfer(contract_address=token_address, recipient=caller_address, amount=amount)
    return ()
end