%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_le, assert_lt
from starkware.starknet.common.syscalls import call_contract, get_caller_address

from contracts.utils.constants import FALSE, TRUE

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

# @storage_var
# func owner_balance(address: felt) -> (res: Uint256):
# end

# @storage_var
# func owner_nonce(address: felt) -> (res: felt):
# end

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

# @view
# func get_owner_nonce{
#         syscall_ptr: felt*,
#         pedersen_ptr: HashBuiltin*,
#         range_check_ptr
#     }(owner_address: felt) -> (value: felt):
#     let (value) = account_nonce.read(owner_address)
#     return (value)
# end

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

@constructor
func constructor{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }(
        owners_len : felt,
        owners : felt*,
    ):
    _owners_len.write(value=owners_len)
    _set_owners(owners_index=0, owners_len=owners_len, owners=owners)
    return ()
end

@external
func execute_transaction{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        to : felt,
        function_selector : felt,
        calldata_len : felt,
        calldata : felt*,
    ) -> (
        response_len: felt,
        response: felt*
    ):
    alloc_locals
    only_in_owners()

    # Execute
    let response = call_contract(
        contract_address=to,
        function_selector=function_selector,
        calldata_size=calldata_len,
        calldata=calldata
    )

    return (response_len=response.retdata_size, response=response.retdata)
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