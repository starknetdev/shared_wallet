%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_le, assert_lt
from starkware.starknet.common.syscalls import call_contract, get_caller_address, get_contract_address
from starkware.cairo.common.uint256 import (
    Uint256,
    uint256_lt,
    uint256_le,
    uint256_eq,
    uint256_add,
    uint256_sub,
    uint256_mul,
    uint256_unsigned_div_rem
)

from openzeppelin.token.erc20.library import (
    ERC20_initializer
)

from openzeppelin.token.erc20.interfaces.IERC20 import IERC20
from contracts.utils.constants import FALSE, TRUE
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
func _tokens(index : felt) -> (res : felt):
end

@storage_var
func _token_weights(token : felt) -> (res : felt):
end

@storage_var
func _share_certificate() -> (res : felt):
end

@storage_var
func _price_oracle() -> (res : felt):
end

@storage_var
func _fund_managers() -> (res : felt):
end

#
# Getters
#

@view
func get_is_owner{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(owner_address : felt) -> (value : felt):
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
end

@view
func _get_token_weights{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        tokens_index : felt,
        tokens_len : felt,
        tokens : felt*,
        token_weights_len : felt,
        token_weights : felt*
    ):
    if tokens_index == tokens_len:
        return ()
    end

    # let (token_weight) = _token_weights.read(token=[tokens])
    let (token_weight) = _token_weights.read(token=tokens[tokens_index])
    assert token_weights[tokens_index] = token_weight

    _get_token_weights(
        tokens_index=tokens_index + 1, 
        tokens_len=tokens_len, 
        tokens=tokens,
        token_weights_len=token_weights_len,
        token_weights=token_weights
    )
    return ()
end

@view
func get_token_weights{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        tokens_len : felt,
        tokens : felt*
    ) -> (
        token_weights_len : felt,
        token_weights : felt*
    ):
    alloc_locals
    let (local token_weights) = alloc()
    if tokens_len == 0:
        return (token_weights_len=tokens_len, token_weights=token_weights)
    end

    # Recursively add owners from storage to the owners array
    _get_token_weights(
        tokens_index=0, 
        tokens_len=tokens_len, 
        tokens=tokens, 
        token_weights_len=tokens_len, 
        token_weights=token_weights
    )
    return (token_weights_len=tokens_len, token_weights=token_weights)
end

func _get_total_weight{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        token_weights : felt*,
        token_weights_len : felt
    ) -> (
        total_weight : felt
    ):
    if token_weights_len == 0:
        return (total_weight=0)
    end

    let (total_weight) = _get_total_weight(token_weights=token_weights + 1, token_weights_len=token_weights_len - 1)

    return (total_weight=[token_weights] + total_weight)
end

@view
func get_total_weight{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (total_weight : felt):
    let (tokens_len, tokens) = get_tokens()
    let (token_weights_len, token_weights) = get_token_weights(tokens_len, tokens)
    
    let (total_weight) = _get_total_weight(token_weights=token_weights, token_weights_len=token_weights_len)

    return (total_weight=total_weight)
end

#
# Guards
#

func only_in_owners{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
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
        tokens_len : felt,
        tokens : felt*,
        token_weights_len : felt,
        token_weights : felt*,
        oracle : felt
    ):
    with_attr error_message("SW Error: Tokens length not equal to weights length"):
        assert tokens_len = token_weights_len
    end
    _owners_len.write(value=owners_len)
    _set_owners(owners_index=0, owners_len=owners_len, owners=owners)
    _tokens_len.write(value=tokens_len)
    _set_tokens(tokens_index=0, tokens_len=tokens_len, tokens=tokens)
    _set_token_weights(
        tokens_index=0, 
        tokens_len=tokens_len, 
        tokens=tokens,
        token_weights=token_weights
    )
    _price_oracle.write(oracle)
    ERC20_initializer(
        'Share Token',
        'ST',
        18
    )
    return ()
end

@external
func add_owners{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        owners_len : felt,
        owners : felt*

    ):
    only_in_owners()
    let (current_owners_len) = _owners_len.read()
    _set_owners(owners_index=current_owners_len, owners_len=current_owners_len + owners_len, owners=owners)
    return ()
end

func _add_funds{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        tokens_index : felt,
        tokens_len : felt,
        tokens : felt*,
        amounts : Uint256*,
        owner : felt
    ):
    alloc_locals
    if tokens_index == tokens_len:
        return ()
    end

    let (local check_amount) = uint256_lt(Uint256(0,0), [amounts])
    with_attr error_message("SW Error: Amount must be greater than 0"):
        assert check_amount = TRUE
    end

    let (contract_address) = get_contract_address()
    IERC20.transferFrom(
        contract_address=tokens[tokens_index], 
        sender=owner, 
        recipient=contract_address, 
        amount=amounts[tokens_index]
    )

    _add_funds(
        tokens_index=tokens_index + 1, 
        tokens_len=tokens_len, 
        tokens=tokens, 
        amounts=amounts, 
        owner=owner
    )
    return ()
end

@external
func add_funds{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        tokens_len : felt,
        tokens : felt*,
        amounts_len : felt,
        amounts : Uint256*
    ):
    alloc_locals
    only_in_owners()
    with_attr error_message("SW Error: Tokens length does not match amounts"):
        assert tokens_len = amounts_len
    end
    # check_weighting(tokens=tokens, amounts=amounts)
    let (caller_address) = get_caller_address()
    let (contract_address) = get_contract_address()

    _add_funds(tokens_index=0, tokens_len=tokens_len, tokens=tokens, amounts=amounts, owner=caller_address)

    # IERC20.mint(contract_address=contract_address, recipient=caller_address, amount=amount)
    # _modify_position(owner=caller_address, share=new_share)
    return ()
end

@external
func remove_funds{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        amount : Uint256
    ):
    alloc_locals
    let (local caller_address) = get_caller_address()
    let (contract_address) = get_contract_address()

    # let (share_certificate) = _share_certificate.read()
    # let (share) = IShareCertificate.get_share(contract_address=share_certificate, owner=caller_address)
    # let (check_amount) = uint256_le(amount, share)
    # with_attr error_message("SW Error: Remove amount cannot be greater than share"):
    #     assert check_amount = TRUE
    # end
    # let (new_share) = uint256_sub(share, amount)
    # _modify_position(owner=caller_address, share=new_share)
    let (amounts_len, amounts) = calculate_share_amounts(owner=caller_address, share=amount)
    distribute_amounts(owner=caller_address, amounts_len=amounts_len, amounts=amounts)
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
        owners : felt*
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

func _set_tokens{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }(
        tokens_index : felt,
        tokens_len : felt,
        tokens : felt*
    ):
    if tokens_index == tokens_len:
        return ()
    end

     # Write the current iteration to storage
    _tokens.write(index=tokens_index, value=[tokens])
    _is_owner.write(owner=[tokens], value=TRUE)

    # Recursively write the rest
    _set_tokens(tokens_index=tokens_index + 1, tokens_len=tokens_len, tokens=tokens + 1)
    return ()
end

func _set_token_weights{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }(
        tokens_index : felt,
        tokens_len : felt,
        tokens : felt*,
        token_weights : felt*
    ):
    if tokens_index == tokens_len:
        return ()
    end

     # Write the current iteration to storage
    _token_weights.write(token=[tokens], value=[token_weights])

    # Recursively write the rest
    _set_token_weights(
        tokens_index=tokens_index + 1, 
        tokens_len=tokens_len,
        tokens=tokens + 1,
        token_weights=token_weights + 1
    )
    return ()
end

#
# Internals
#

# func check_weighting{
#         syscall_ptr : felt*,
#         pedersen_ptr : HashBuiltin*,
#         range_check_ptr
#     }(
#         tokens_len : felt,
#         tokens : felt*,
#         amounts_len : felt,
#         amounts : Uint256*
#     ):
#     let (total_weight) = get_total_weight()
#     _check_weighting(
#         tokens_index=0, 
#         tokens_len=tokens_len,
#         tokens=tokens,
#         amounts_len=amounts_len,
#         amounts=amounts,
#         total_weight=total_weight,
#     )
#     return ()
# end

# func _check_weighting{
#         syscall_ptr : felt*,
#         pedersen_ptr : HashBuiltin*,
#         pedersen_ptr
#     }(
#         tokens_len : felt,
#         tokens : felt*,
#         amounts_len : felt,
#         amounts : Uint256*,
#         total_weight : felt
#     ):
#     if token_index == tokens_len:
#         return ()
#     end

#     let (fund_token_weight) = _token_weights.read(token=[tokens])
#     let (check_fund_token_weight) = fund_token_weight / total_weight
#     let (check_added_token_weight) = [amounts] / total_amount
#     with_attr error_message("SW Error: Added funds weighting does not equal required weights"):
#         assert check_fund_token_weight = check_added_token_weight
#     end

#     _check_weighting(
#         tokens_index=tokens_index + 1, 
#         tokens_len=tokens_len, 
#         tokens=tokens + 1, 
#         amounts_len=amounts_len, 
#         amounts=amounts + 1, 
#         total_weight=total_weight
#     )
#     return()
# end



# func _modify_position{
#         syscall_ptr : felt*,
#         pedersen_ptr : HashBuiltin*,
#         range_check_ptr
#     }(
#         owner : felt,
#         share : Uint256
#     ):
#     alloc_locals
#     let (local share_certificate) = _share_certificate.read()
#     let (caller_address) = get_caller_address()
#     let (owner_certificate) = IShareCertificate.get_certificate_id(
#         contract_address=share_certificate,
#         owner=owner
#     )
#     let (check_certificate_zero) = uint256_eq(owner_certificate,Uint256(0,0))
#     if check_certificate_zero == TRUE:
#         IShareCertificate.mint(contract_address=share_certificate, owner=caller_address, share=share)
#     else:
#         let (check_share_zero) = uint256_eq(share,Uint256(0,0))
#         IShareCertificate.burn(contract_address=share_certificate, owner=owner)
#         if check_share_zero == TRUE:
#             return()
#         else:
#             IShareCertificate.mint(contract_address=share_certificate, owner=caller_address, share=share)
#         end
#     end
#     return ()
# end

func _get_price{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(token : felt) -> (price : Uint256):
    let (price_oracle) = _price_oracle.read()
    let (price) = IPriceAggregator.get_data(contract_address=price_oracle, token=token)
    return (price)
end

func _get_reserve_value{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        tokens_index : felt,
        tokens_len : felt, 
        tokens : felt*,
        total_value : Uint256
    ):
    if tokens_index == tokens_len:
        return ()
    end

    let (token) = _tokens.read(index=tokens_index)
    let (contract_address) = get_contract_address()
    let (reserve) = IERC20.balanceOf(contract_address=token, account=contract_address)
    let (price) = _get_price(token=token)
    let (reserve_value, _) = uint256_mul(price, reserve)
    let (new_total_value, _) = uint256_add(total_value, reserve_value)
    assert total_value = new_total_value

    _get_reserve_value(
        tokens_index=tokens_index + 1, 
        tokens_len=tokens_len, 
        tokens=tokens, 
        total_value=total_value
    )
    return ()
end

@view
func get_total_reserve_value{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        tokens_len : felt,
        tokens : felt*
    ) -> (
        total_value : Uint256
    ):
    alloc_locals
    local total_value : Uint256 = Uint256(0,0)

    let (tokens_len) = _tokens_len.read()
    if tokens_len == 0:
        return (total_value)
    end

    # Recursively sum total value from reserves
    _get_reserve_value(tokens_index=0, tokens_len=tokens_len, tokens=tokens, total_value=total_value)
    return (total_value=total_value)
end


# Calculates share amounts
@view
func calculate_share_amounts{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        owner : felt,
        share : Uint256
    ) -> (
        amounts_len : felt,
        amounts : Uint256*
    ):
    alloc_locals
    let (local tokens_len, tokens) = get_tokens()
    let (total_value) = get_total_reserve_value(tokens_len, tokens)
    let (reserves_len, reserves) = get_token_reserves()
    let (amounts_len, amounts) = calculate_share_of_tokens(
        reserves_len=reserves_len, 
        reserves=reserves,
        share=share,
        total_value=total_value
    )
    return (amounts_len, amounts)
end

func calculate_share_of_tokens{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        reserves_len : felt,
        reserves : Uint256*,
        share : Uint256,
        total_value : Uint256
    ) -> (
        amounts_len : felt,
        amounts : Uint256*
    ):
    alloc_locals
    let (local amounts : Uint256*) = alloc()
    if reserves_len == 0:
        return (amounts_len=reserves_len, amounts=amounts)
    end

    # Recursively add amounts from calculation to the amounts array
    _calculate_share_of_tokens(
        reserves_index=0, 
        reserves_len=reserves_len, 
        reserves=reserves,
        share=share,
        total_value=total_value,
        amounts=amounts
    )
    return (amounts_len=reserves_len, amounts=amounts)
end

func _calculate_share_of_tokens{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        reserves_index : felt,
        reserves_len : felt,
        reserves : Uint256*,
        share : Uint256,
        total_value : Uint256,
        amounts : Uint256*
    ):
    if reserves_index == reserves_len:
        return ()
    end

    let (amount_numerator, _) = uint256_mul([amounts], share)
    let (amount, _) = uint256_unsigned_div_rem(amount_numerator, total_value)
    assert amounts[reserves_index] = amount

    _calculate_share_of_tokens(
        reserves_index=reserves_index + 1,
        reserves_len=reserves_len,
        reserves=reserves,
        share=share,
        total_value=total_value,
        amounts=amounts
    )
    return ()
end

func get_token_reserves{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (
        reserves_len : felt,
        reserves : Uint256*
    ):
    alloc_locals
    let (local tokens_len, tokens) = get_tokens()
    let (local reserves: Uint256*) = alloc()
    if tokens_len == 0:
        return (reserves_len=tokens_len, reserves=reserves)
    end

    # Recursively add reserves from storage to the reserves array
    _get_token_reserves(tokens_index=0, tokens_len=tokens_len, tokens=tokens, reserves=reserves)
    return (reserves_len=tokens_len, reserves=reserves)
end

    
func _get_token_reserves{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        tokens_index : felt,
        tokens_len : felt, 
        tokens : felt*,
        reserves : Uint256*
    ):
    if tokens_index == tokens_len:
        return ()
    end

    let (token) = _tokens.read(index=tokens_index)
    let (contract_address) = get_contract_address()
    let (reserve) = IERC20.balanceOf(contract_address=token, account=contract_address)
    assert reserves[tokens_index] = reserve

    _get_token_reserves(tokens_index=tokens_index + 1, tokens_len=tokens_len, tokens=tokens, reserves=reserves)
    return ()
end

func distribute_amounts{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        owner : felt,
        amounts_len : felt,
        amounts : Uint256*
    ):
    if amounts_len == 0:
        return ()
    end
    let (token_len, tokens) = get_tokens()

    # Recursively send tokens to the owner
    _distribute_amounts(
        amounts_index=0, 
        amounts_len=amounts_len,
        amounts=amounts,
        owner=owner,
        tokens=tokens
    )
    return ()
end

func _distribute_amounts{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        amounts_index : felt,
        amounts_len : felt,
        amounts : Uint256*,
        owner : felt,
        tokens : felt*
    ):
    if amounts_index == amounts_len:
        return ()
    end

    IERC20.transfer(contract_address=[tokens], recipient=owner, amount=[amounts])
    return ()
end

