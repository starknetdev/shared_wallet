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
        tokens_len: felt,
        tokens: felt*,
        prices_len: felt,
        prices: Uint256*
    ):
    with_attr error_message("Oracle Error: Tokens length not equal to prices length"):
        assert tokens_len = prices_len
    end
    set_multiple_data(0, tokens_len, tokens, prices_len, prices)
    return()
end
    

@view
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

func set_multiple_data{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        asset_type_index: felt,
        asset_type_len: felt,
        asset_type: felt*,
        prices_len: felt,
        prices: Uint256*
    ):
    if asset_type_index == asset_type_len:
        return ()
    end

    set_data(asset_type=asset_type[asset_type_index], value=prices[asset_type_index])

    # Recursively write the rest
    set_multiple_data(
        asset_type_index=asset_type_index + 1, 
        asset_type_len=asset_type_len, 
        asset_type=asset_type,
        prices_len=prices_len,
        prices=prices
    )
    return ()
end

