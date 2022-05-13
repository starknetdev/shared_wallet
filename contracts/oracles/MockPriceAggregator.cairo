%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_le, assert_lt
from starkware.starknet.common.syscalls import call_contract, get_caller_address, get_contract_address
from starkware.cairo.common.uint256 import (
    Uint256,
    uint256_lt
)

from openzeppelin.token.erc20.interfaces.IERC20 import IERC20

#
# Storage variables
#

@storage_var
func datastore(token: felt) -> (res: Uint256):
end

@storage_var
func decimals(token: felt) -> (res: felt):
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
    set_multiple_data(
        tokens_index=0, 
        tokens_len=tokens_len, 
        tokens=tokens, 
        prices_len=prices_len, 
        prices=prices
    )
    return()
end

#
# Getters
#   

@view
func get_data{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(token: felt) -> (
        value: Uint256,
        decimals: felt
    ):
    
    let value: Uint256 = datastore.read(token)
    let (decimals_value) = decimals.read(token)

    return (value, decimals_value)
end

#
# Actions
#

@external
func set_data{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        token: felt, 
        value: Uint256
    ):

    datastore.write(token, value)
    return()
end

@external
func set_decimals{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        token: felt, 
        value: felt
    ):
    
    decimals.write(token, value)
    return()
end

func set_multiple_data{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        tokens_index: felt,
        tokens_len: felt,
        tokens: felt*,
        prices_len: felt,
        prices: Uint256*
    ):
    if tokens_index == tokens_len:
        return ()
    end

    set_data(token=tokens[tokens_index], value=prices[tokens_index])
    let (decimals) = IERC20.decimals(contract_address=tokens[tokens_index])
    set_decimals(token=tokens[tokens_index], value=decimals)

    # Recursively write the rest
    set_multiple_data(
        tokens_index=tokens_index + 1, 
        tokens_len=tokens_len, 
        tokens=tokens,
        prices_len=prices_len,
        prices=prices
    )
    return ()
end

