%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_le, assert_lt
from starkware.starknet.common.syscalls import call_contract, get_caller_address, get_contract_address
from starkware.cairo.common.uint256 import (
    Uint256,
    uint256_lt,
    uint256_eq,
    uint256_add,
    uint256_sub, 
    uint256_div
)

from openzeppelin.token.erc20.interfaces.IERC20 import IERC20
from contracts.utils.constants import FALSE, TRUE
from contracts.interfaces.IShareCertificate import IShareCertificate
from contracts.interfaces.IPriceAggregator import IPriceAggregator

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
func _is_owner(owner : felt) -> (res : felt):
end

@storage_var
func _tokens_len() -> (res : felt):
end

@storage_var
func _tokens(index: felt) -> (res: felt):
end

@storage_var
func _token_reserve(token: felt) -> (res: Uint256):
end

@storage_var
func owner_balance(owner: felt, token: felt) -> (res: Uint256):
end

@storage_var
func _share_certificate() -> (res: felt):
end

@storage_var
func _price_oracle() -> (res: felt):
end

@storage_var
func _fund_managers() -> (res: felt):
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
func _get_tokens{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        tokens_index : felt,
        tokens_len : felt,
        tokens : felt*,
    ):
    if tokens_index == tokens_len:
        return ()
    end

    let (token) = _tokens.read(index=tokens_index)
    assert tokens[tokens_index] = token

    _get_tokens(tokens_index=tokens_index + 1, tokens_len=tokens_len, tokens=tokens)
    return ()
end

@view
func get_tokens{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (
        tokens_len : felt,
        tokens : felt*
    ):
    alloc_locals
    let (tokens) = alloc()
    let (tokens_len) = _tokens_len.read()
    if tokens_len == 0:
        return (tokens_len=tokens_len, tokens=tokens)
    end

    # Recursively add tokens from storage to the tokens array
    _get_tokens(tokens_index=0, tokens_len=tokens_len, tokens=tokens)
    return (tokens_len=tokens_len, tokens=tokens)

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

@constructor
func constructor{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }(
        owners_len : felt,
        owners : felt*,
        share_certificate : felt,
        oracle : felt
    ):
    _owners_len.write(value=owners_len)
    _set_owners(owners_index=0, owners_len=owners_len, owners=owners)
    _share_certificate.write(share_certificate)
    _price_oracle.write(oracle)
    return ()
end

@external
func add_owners{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        owners_len: felt,
        owners: felt*

    ):
    only_in_owners()
    let (current_owners_len) = _owners_len.read()
    _set_owners(owners_index=current_owners_len, owners_len=current_owners_len + owners_len, owners=owners)
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
    only_in_owners()
    let (local check_amount) = uint256_lt(Uint256(0,0), amount)
    with_attr error_message("SW Error: Amount must be greater than 0"):
        assert check_amount = TRUE
    end
    let (caller_address) = get_caller_address()
    let (current_balance) = owner_balance.read(caller_address, token)
    let (new_balance, _) = uint256_add(current_balance, amount)
    owner_balance.write(owner=caller_address, token=token, value=new_balance)

    let (current_reserve) = _token_reserve.read(token)
    let (new_reserve, _) = uint256_add(current_reserve, amount)
    _token_reserve.write(token, new_reserve)

    let (contract_address) = get_contract_address()
    IERC20.transferFrom(
        contract_address=token, 
        sender=caller_address, 
        recipient=contract_address, 
        amount=amount
    )

    let (share) = _calculate_total_share(owner=caller_address)
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

    let (current_balance) = owner_balance.read(caller_address, token)
    let (new_balance) = uint256_sub(current_balance, amount)
    owner_balance.write(owner=caller_address, token=token, value=new_balance)
    
    let (current_reserve) = _token_reserve.read(token)
    let (new_reserve) = uint256_sub(current_reserve, amount)
    _token_reserve.write(token, new_reserve)

    # _modify_position(owner=caller_address, amount)
    IERC20.transfer(contract_address=token, recipient=caller_address, amount=amount)


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
    _is_owner.write(owner=[owners], value=TRUE)

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
    }(
        owner: felt,
        token: felt, 
        amount: Uint256
    ):
    let (share_certificate) = _share_certificate.read()
    let (caller_address) = get_caller_address()
    IShareCertificate.burn(contract_address=share_certificate, owner=owner, token=token)
    IShareCertificate.mint(contract_address=share_certificate, owner=caller_address, token=token, share=amount)
    return ()
end

func _get_price{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        token: felt
    ):
    let (price_oracle) = _price_oracle.read()
    let (price) = IPriceAggregator.get_data(contract_address=price_oracle, token=token)
    return (price)
end

func _get_reserve_value{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        tokens_index: felt,
        tokens_len: felt, 
        tokens: felt*
    ):
    if tokens_index == tokens_len:
        return ()
    end

    let (token) = _tokens.read(index=tokens_index)
    let (price) = _get_price(token=token)
    let (reserve) = _token_reserve.read(token)
    let (reserve_value) = uint256_mul(price, reserve_value)
    assert total_value = uint256_add(total_value, reserve_value)

    _get_reserve_value(tokens_index=tokens_index + 1, tokens_len=tokens_len, tokens=tokens)
    return ()
end


func get_total_reserve_value{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        tokens_len: felt,
        tokens: felt*
    ) -> (
        total_value: Uint256
    ):
    alloc_locals
    let (total_value) = alloc()

    let (tokens_len) = _tokens_len.read()
    if tokens_len == 0:
        return (reserve_value)
    end

    # Recursively sum total value from reserves
    _get_reserve_value(tokens_index=0, tokens_len=tokens_len, tokens=tokens)
    return (total_value=total_value)
end

func _get_owner_value{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        owner: felt,
        tokens_index: felt,
        tokens_len: felt, 
        tokens: felt*
    ):
    if tokens_index == tokens_len:
        return ()
    end

    let (token) = _tokens.read(index=tokens_index)
    let (price) = _get_price(token=token)
    let (balance) = _owner_balance.read(owner, token)
    let (balance_value) = uint256_mul(price, balance)
    assert owner_value = uint256_add(owner_value, balance_value)

    _get_owner_value(owner=owner, tokens_index=tokens_index + 1, tokens_len=tokens_len, tokens=tokens)
    return ()
end

func get_owner_value{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        owner: felt,
        tokens_len: felt,
        tokens: felt*
    ) -> (
        owner_value: Uint256
    ):
    alloc_locals
    let (owner_value) = alloc()

    let (tokens_len) = _tokens_len.read()
    if tokens_len == 0:
        return (owner_value)
    end

    # Recursively sum owner value from the balances
    _get_owner_value(owner=owner, tokens_index=0, tokens_len=tokens_len, tokens=tokens)
    return (owner_value=owner_value)
end

# Calculates total share with oracles
func _calculate_total_share{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        owner: felt
    ) -> (
        share: Uint256
    ):
    let (tokens_len, tokens) = get_tokens()
    let (total_value) = get_total_reserve_value(tokens_len, tokens)
    let (owner_value) = get_owner_reserve_value(owner, tokens_len, tokens)
    let (share) = uint256_div(owner_value, total_value)
    return (share)
end
    