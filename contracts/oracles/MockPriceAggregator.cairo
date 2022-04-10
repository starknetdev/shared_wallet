%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_le, assert_lt
from starkware.starknet.common.syscalls import call_contract, get_caller_address, get_contract_address
from starkware.cairo.common.uint256 import (
    Uint256,
    uint256_lt
)

#
# Storage variables
#

@storage_var
func datastore(asset_type: felt) -> (res: Uint256):
end
#
# Constructor
#

@constructor
func constructor{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        token: felt,
        price: Uint256
    ):
    set_data(token, price)
    return()
end
    

@external
func get_data{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*,
        range_check_ptr}(asset_type:felt) -> (value:Uint256):
    
    let current_value:Uint256 = datastore.read(asset_type)

    return (current_value)
end

@external
func set_data{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*,
        range_check_ptr}(asset_type: felt, value: Uint256):
    

    datastore.write(asset_type, value)
    return()
end