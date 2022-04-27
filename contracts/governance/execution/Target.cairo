%lang starknet

## A mock target contract for testing multisig functionality

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_tx_signature
from starkware.cairo.common.math import unsigned_div_rem
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.uint256 import Uint256

# Define a storage variable.
@storage_var
func balance() -> (res : Uint256):
end

@constructor
func constructor{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr
} ():
    return ()
end

@external
func execute{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        proposal_outcome : felt, execution_hash : Uint256, execution_params_len : felt,
        execution_params : felt*):
    if proposal_outcome == 1:
        set_balance(execution_hash)
    else:
        return ()
    end
    return ()
end

@external
func set_balance{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*,
        range_check_ptr}(_balance : Uint256):
    balance.write(_balance)
    return ()
end

# Returns the current balance.
@view
func get_balance{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*,
        range_check_ptr}() -> (res : Uint256):
    let (res) = balance.read()
    return (res)
end