%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_le, assert_lt
from starkware.cairo.common.pow import pow
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

from openzeppelin.token.erc20.interfaces.IERC20 import IERC20

from contracts.utils.constants import FALSE, TRUE
from contracts.interfaces.IPriceAggregator import IPriceAggregator
from contracts.interfaces.IShareCertificate import IShareCertificate
from contracts.libraries.Math64x61 import (
    Math64x61_div,
    Math64x61_mul
)

#
# Storage
#

@storage_var
func _tokens_len() -> (res : felt):
end

@storage_var
func _tokens(index : felt) -> (res : felt):
end

@storage_var
func _token_reserves(token: felt) -> (res : Uint256):
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

#
# Getters
#

@view
func get_is_owner{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(owner_address : felt) -> (value : felt):
    let (share_certificate) = _share_certificate.read()
    let (balance) = IShareCertificate.balanceOf(contract_address=share_certificate, owner=owner_address)
    let (check) = assert_lt(0,balance)
    return (check)
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

func only_owner{
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
        tokens_len : felt,
        tokens : felt*,
        token_weights_len : felt,
        token_weights : felt*,
        oracle : felt,
        share_certificate : felt
    ):
    with_attr error_message("SW Error: Tokens length not equal to weights length"):
        assert tokens_len = token_weights_len
    end
    _tokens_len.write(value=tokens_len)
    _set_tokens(tokens_index=0, tokens_len=tokens_len, tokens=tokens)
    _set_token_weights(
        tokens_index=0, 
        tokens_len=tokens_len, 
        tokens=tokens,
        token_weights=token_weights
    )
    _price_oracle.write(oracle)
    _share_certificate.write(share_certificate)
    return ()
end

# # Function to be implemented when factories available
# func shared_wallet_initializer{
#         syscall_ptr : felt*,
#         pedersen_ptr : HashBuiltin*,
#         range_check_ptr,
#     }(
#         tokens_len : felt,
#         tokens : felt*,
#         token_weights_len : felt,
#         token_weights : felt*,
#         oracle : felt,
#         share_certificate : felt
#     ):
#     with_attr error_message("SW Error: Tokens length not equal to weights length"):
#         assert tokens_len = token_weights_len
#     end
#     _tokens_len.write(value=tokens_len)
#     _set_tokens(tokens_index=0, tokens_len=tokens_len, tokens=tokens)
#     _set_token_weights(
#         tokens_index=0, 
#         tokens_len=tokens_len, 
#         tokens=tokens,
#         token_weights=token_weights
#     )
#     _price_oracle.write(oracle)
#     _share_certificate.write(share_certificate)
#     return ()
# end

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
    with_attr error_message("SW Error: Tokens length does not match amounts"):
        assert tokens_len = amounts_len
    end
    # check_weighting(
    #     tokens_len=tokens_len, 
    #     tokens=tokens, 
    #     amounts_len=amounts_len,
    #     amounts=amounts
    # )
    let (caller_address) = get_caller_address()
    let (contract_address) = get_contract_address()

    _add_funds(tokens_index=0, tokens_len=tokens_len, tokens=tokens, amounts=amounts, owner=caller_address)

    _modify_position_add(owner=caller_address, tokens_len=tokens_len, tokens=tokens, amounts_len=amounts_len, amounts=amounts)
    update_reserves()
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
    only_owner()
    let (local caller_address) = get_caller_address()
    let (contract_address) = get_contract_address()

    let (share_certificate) = _share_certificate.read()
    let (token_id) = IShareCertificate.get_certificate_id(contract_address=share_certificate, owner=caller_address, fund=contract_address)
    let (share) = IShareCertificate.get_shares(contract_address=share_certificate, token_id=token_id)
    let (check_amount) = uint256_le(amount, share)
    with_attr error_message("SW Error: Remove amount cannot be greater than share"):
        assert check_amount = TRUE
    end
    let (amounts_len, amounts) = calculate_tokens_from_share(share=amount)
    distribute_amounts(owner=caller_address, amounts_len=amounts_len, amounts=amounts)
    _modify_position_remove(owner=caller_address, share=amount)
    update_reserves()
    return ()
end

#
# Storage Helpers
#

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

@external
func check_weighting{
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
    let (total_weight) = get_total_weight()
    _check_weighting(
        tokens_index=0, 
        tokens_len=tokens_len,
        tokens=tokens,
        amounts_len=amounts_len,
        amounts=amounts,
        total_weight=total_weight
    )
    return ()
end

func _check_weighting{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        tokens_index : felt,
        tokens_len : felt,
        tokens : felt*,
        amounts_len : felt,
        amounts : Uint256*,
        total_weight : felt
    ):
    alloc_locals
    if tokens_index == tokens_len:
        return ()
    end
    let (oracle) = _price_oracle.read()
    let (total_usd_amount) = get_total_usd_amount(
        tokens_len=tokens_len, 
        tokens=tokens, 
        amounts_len=amounts_len, 
        amounts=amounts
    )
    let (token_decimals) = IERC20.decimals(contract_address=tokens[tokens_index])

    let (fund_token_weight) = _token_weights.read(token=tokens[tokens_index])
    let (check_fund_token_weight) = Math64x61_div(fund_token_weight, total_weight)
    let (check_fund_token_units) = pow(10,token_decimals)
    let (check_fund_token) = Math64x61_mul(check_fund_token_weight, check_fund_token_units)
    
    let (token_price, token_price_decimals) = IPriceAggregator.get_data(contract_address=oracle, token=tokens[tokens_index])
    let (check_fund_token_units) = pow(10,token_price_decimals)
    let token_price_units_uint: Uint256 = Uint256(check_fund_token_units,0)
    let (token_price_units, _) = uint256_unsigned_div_rem(token_price, token_price_units_uint)

    let (token_usd_amount, _) = uint256_mul(amounts[tokens_index], token_price_units)
    let (total_usd, _) = uint256_unsigned_div_rem(total_usd_amount, token_price_units_uint)
    let (check_added_token_weight, _) = uint256_unsigned_div_rem(token_usd_amount, total_usd)
    let check_fund_token_weight_uint: Uint256 = Uint256(check_fund_token,0)
    let (check_equal) = uint256_eq(check_fund_token_weight_uint, check_added_token_weight)
    with_attr error_message("SW Error: Added funds weighting does not equal required weights"):
        assert check_equal = TRUE
    end

    _check_weighting(
        tokens_index=tokens_index + 1, 
        tokens_len=tokens_len, 
        tokens=tokens, 
        amounts_len=amounts_len, 
        amounts=amounts, 
        total_weight=total_weight
    )
    return()
end

@view
func get_total_usd_amount{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        tokens_len : felt,
        tokens : felt*,
        amounts_len : felt,
        amounts : Uint256*
    ) -> (
        total_amount : Uint256
    ):
    if amounts_len == 0:
        return (total_amount=Uint256(0,0))
    end

    let (total_amount) = _get_total_usd_amount(
        tokens_index=0,
        tokens_len=tokens_len,
        tokens=tokens, 
        amounts_len=amounts_len, 
        amounts=amounts, 
        total_amount=Uint256(0,0)
    )
    return (total_amount=total_amount)
end

func _get_total_usd_amount{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        tokens_index : felt,
        tokens_len : felt,
        tokens : felt*,
        amounts_len : felt,
        amounts : Uint256*,
        total_amount : Uint256
    ) -> (
        new_amount : Uint256
    ):
    alloc_locals
    if tokens_index == amounts_len:
        return (new_amount=total_amount)
    end
    let (oracle) = _price_oracle.read()

    let (local token_price, token_price_decimals) = IPriceAggregator.get_data(contract_address=oracle, token=tokens[tokens_index])
    let (check_fund_token_units) = pow(10,token_price_decimals)
    let token_price_units_uint: Uint256 = Uint256(check_fund_token_units,0)
    let (token_price_units, _) = uint256_unsigned_div_rem(token_price, token_price_units_uint)

    let (token_usd_amount, _) = uint256_mul(amounts[tokens_index], token_price_units)
    let (new_amount, _) = uint256_add(total_amount, token_usd_amount)
    let (new_amount) = _get_total_usd_amount(
        tokens_index=tokens_index + 1,
        tokens_len=tokens_len,
        tokens=tokens,
        amounts_len=amounts_len,
        amounts=amounts, 
        total_amount=new_amount
    )
    return (new_amount)

end

func _modify_position_add{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        owner : felt,
        tokens_len : felt,
        tokens : felt*,
        amounts_len : felt,
        amounts : Uint256*
    ):
    alloc_locals
    let (contract_address) = get_contract_address()
    let (caller_address) = get_caller_address()
    let (share_certificate) = _share_certificate.read()
    let (current_total_supply) = IShareCertificate.get_total_shares(contract_address=share_certificate, fund=contract_address)
    let (token_id) = IShareCertificate.get_certificate_id(contract_address=share_certificate, owner=caller_address, fund=contract_address)
    let (share) = IShareCertificate.get_shares(contract_address=share_certificate, token_id=token_id)
    let (check_supply_zero) = uint256_eq(current_total_supply, Uint256(0,0))
    let (check_share_zero) = uint256_eq(share, Uint256(0,0))
    let (initial_share: Uint256) = calculate_initial_share(tokens_len=tokens_len, tokens=tokens, amounts_len=amounts_len, amounts=amounts)
    let (added_share: Uint256) = calculate_share(tokens_len=tokens_len, tokens=tokens, amounts_len=amounts_len, amounts=amounts)

    if check_supply_zero == TRUE:
        IShareCertificate.mint(contract_address=share_certificate, owner=owner, share=initial_share, fund=contract_address)
    else:
        if check_share_zero == TRUE:
            IShareCertificate.mint(contract_address=share_certificate, owner=owner, share=added_share, fund=contract_address)
        else:
            let (token_id) = IShareCertificate.get_certificate_id(contract_address=share_certificate, owner=owner, fund=contract_address)
            IShareCertificate.increase_shares(contract_address=share_certificate, token_id=token_id, amount=added_share)
        end
    end
    return ()
end

func _modify_position_remove{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        owner : felt,
        share : Uint256
    ):
    alloc_locals
    let (contract_address) = get_contract_address()
    let (share_certificate) = _share_certificate.read()
    let (token_id) = IShareCertificate.get_certificate_id(contract_address=share_certificate, owner=owner, fund=contract_address)
    let (current_shares) = IShareCertificate.get_shares(contract_address=share_certificate, token_id=token_id)
    let (check_share) = uint256_le(current_shares, share)
    if check_share == TRUE:
        let (token_id) = IShareCertificate.get_certificate_id(contract_address=share_certificate, owner=owner, fund=contract_address)
        IShareCertificate.burn(contract_address=share_certificate, token_id=token_id)
    else:
        let (token_id) = IShareCertificate.get_certificate_id(contract_address=share_certificate, owner=owner, fund=contract_address)
        IShareCertificate.decrease_shares(contract_address=share_certificate, token_id=token_id, amount=share)
    end
    return ()
end

func update_reserves{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }():
    alloc_locals
    let (local tokens_len, tokens) = get_tokens()
    let (balances_len, balances) = get_token_balances()

    _update_reserves(
        tokens_index=0,
        tokens_len=tokens_len,
        tokens=tokens,
        balances_len=balances_len,
        balances=balances
    )

    return ()
end

func _update_reserves{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        tokens_index : felt,
        tokens_len : felt,
        tokens : felt*,
        balances_len : felt,
        balances : Uint256*
    ):
    if tokens_index == tokens_len:
        return ()
    end

    _token_reserves.write(token=tokens[tokens_index], value=balances[tokens_index])

    _update_reserves(
        tokens_index=tokens_index + 1,
        tokens_len=tokens_len,
        tokens=tokens,
        balances_len=balances_len,
        balances=balances
    )

    return ()
end

@view
func calculate_tokens_from_share{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        share : Uint256
    ) -> (
        amounts_len : felt,
        amounts : Uint256*
    ):
    alloc_locals
    let (local amounts : Uint256*) = alloc()
    let (tokens_len, tokens) = get_tokens()
    let (reserves_len, reserves) = get_token_reserves()
    if reserves_len == 0:
        return (amounts_len=reserves_len, amounts=amounts)
    end

    # Recursively add amounts from calculation to the amounts array
    _calculate_tokens_from_share(
        tokens_index=0,
        tokens_len=tokens_len,
        tokens=tokens,
        reserves_len=reserves_len, 
        reserves=reserves,
        share=share,
        amounts_len=reserves_len,
        amounts=amounts
    )
    return (amounts_len=reserves_len, amounts=amounts)
end

func _calculate_tokens_from_share{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        tokens_index : felt,
        tokens_len : felt,
        tokens : felt*,
        reserves_len : felt,
        reserves : Uint256*,
        share : Uint256,
        amounts_len : felt,
        amounts : Uint256*
    ):
    alloc_locals
    if tokens_index == tokens_len:
        return ()
    end

    let (contract_address) = get_contract_address()
    let (share_certificate) = _share_certificate.read()
    let (total_supply) = IShareCertificate.get_total_shares(contract_address=share_certificate, fund=contract_address)
    let (token_decimals) = IERC20.decimals(contract_address=tokens[tokens_index])
    let (token_units) = pow(10,token_decimals)

    let unit_reserve_divisor: Uint256 = Uint256(token_units,0)
    let (get_share_units, _) = uint256_unsigned_div_rem(share, unit_reserve_divisor)
    let (get_reserve_units, _) = uint256_unsigned_div_rem(reserves[tokens_index], unit_reserve_divisor)
    let (get_total_supply_units, _) = uint256_unsigned_div_rem(total_supply, unit_reserve_divisor)

    let (amount_numerator, _) = uint256_mul(get_share_units, get_reserve_units)
    let (amount_units, _) = uint256_unsigned_div_rem(amount_numerator, get_total_supply_units)
    let (amount, _) = uint256_mul(amount_units, unit_reserve_divisor)
    assert amounts[tokens_index] = amount

    _calculate_tokens_from_share(
        tokens_index=tokens_index + 1,
        tokens_len=tokens_len,
        tokens=tokens,
        reserves_len=reserves_len,
        reserves=reserves,
        share=share,
        amounts_len=amounts_len,
        amounts=amounts
    )
    return ()
end

@view
func calculate_initial_share{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        tokens_len : felt,
        tokens : felt*,
        amounts_len : felt,
        amounts : Uint256*
    ) -> (
        initial_share : Uint256
    ):
    alloc_locals
    let initial_share: Uint256 = Uint256(1000000000000000000,0)

    if amounts_len == 0:
        return (initial_share=Uint256(0,0))
    end
    
    let (new_share) = _calculate_initial_share(
        tokens_index=0,
        tokens_len=tokens_len,
        tokens=tokens,
        amounts_len=amounts_len, 
        amounts=amounts,
        initial_share=initial_share
    )
    return (initial_share=new_share) 
end

func _calculate_initial_share{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        tokens_index : felt,
        tokens_len : felt,
        tokens : felt*,
        amounts_len : felt,
        amounts : Uint256*,
        initial_share : Uint256
    ) -> (
        new_share : Uint256
    ):
    alloc_locals
    if tokens_index == tokens_len:
        return (new_share=initial_share)
    end
    let (token_decimals) = IERC20.decimals(contract_address=tokens[tokens_index])
    let (token_units) = pow(10,token_decimals)
    let unit_initial_divisor: Uint256 = Uint256(token_units,0)
    let unit_amount_divisor: Uint256 = Uint256(token_units,0)
    if tokens_index == 0:
        assert unit_initial_divisor = Uint256(1000000000000000000,0)
    end
    let (get_initial_units, _) = uint256_unsigned_div_rem(initial_share, unit_initial_divisor)
    let (get_amount_units, _) = uint256_unsigned_div_rem(amounts[tokens_index], unit_amount_divisor)
    let (new_share_units, _) = uint256_mul(get_initial_units, get_amount_units)
    let (new_share, _) = uint256_mul(new_share_units, unit_amount_divisor)

    let (new_share) = _calculate_initial_share(
        tokens_index=tokens_index + 1, 
        tokens_len=tokens_len,
        tokens=tokens,
        amounts_len=amounts_len, 
        amounts=amounts, 
        initial_share=new_share
    )
    return (new_share=new_share)
end

@view
func calculate_share{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        tokens_len : felt,
        tokens : felt*,
        amounts_len : felt,
        amounts : Uint256*
    ) -> (
        share : Uint256
    ):
    alloc_locals
    let (local share_amounts : Uint256*) = alloc()
    let (reserves_len, reserves) = get_token_reserves()

    if amounts_len == 0:
        return (share=Uint256(0,0))
    end

    _calculate_share_amounts(
        tokens_index=0,
        tokens_len=tokens_len,
        tokens=tokens,
        amounts_len=amounts_len,
        amounts=amounts,
        reserves_len=reserves_len,
        reserves=reserves,
        share_amounts_len=amounts_len,
        share_amounts=share_amounts
    )

    let (share) = get_minimum_amount(amounts_len=amounts_len, amounts=share_amounts)

    return (share=share)
end

func _calculate_share_amounts{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        tokens_index : felt,
        tokens_len : felt,
        tokens : felt*,
        amounts_len : felt,
        amounts : Uint256*,
        reserves_len : felt,
        reserves : Uint256*,
        share_amounts_len : felt,
        share_amounts : Uint256*
    ): 
    alloc_locals
    if tokens_index == tokens_len:
        return ()
    end
    
    let (contract_address) = get_contract_address()
    let (share_certificate) = _share_certificate.read()
    let (total_supply) = IShareCertificate.get_total_shares(contract_address=share_certificate, fund=contract_address)

    let (token_decimals) = IERC20.decimals(contract_address=tokens[tokens_index])
    let (token_units) = pow(10,token_decimals)
    let unit_amount_divisor: Uint256 = Uint256(token_units,0)
    let (get_amount_units, _) = uint256_unsigned_div_rem(amounts[tokens_index], unit_amount_divisor)
    let (get_total_supply_units, _) = uint256_unsigned_div_rem(total_supply, unit_amount_divisor)
    let (get_reserves_units, _) = uint256_unsigned_div_rem(reserves[tokens_index], unit_amount_divisor)

    let (amount_numerator, _) = uint256_mul(get_amount_units, get_total_supply_units)
    let (amount_units, _) = uint256_unsigned_div_rem(amount_numerator, get_reserves_units)
    let (amount, _) = uint256_mul(amount_units, unit_amount_divisor)
    assert share_amounts[tokens_index] = amount

    _calculate_share_amounts(
        tokens_index=tokens_index + 1,
        tokens_len=tokens_len,
        tokens=tokens,
        amounts_len=amounts_len,
        amounts=amounts,
        reserves_len=reserves_len,
        reserves=reserves,
        share_amounts_len=share_amounts_len,
        share_amounts=share_amounts
    )

    return()
end

@view
func get_minimum_amount{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        amounts_len : felt,
        amounts : Uint256*
    ) -> (
        minimum : Uint256
    ):
    if amounts_len == 0:
        return (minimum=Uint256(0,0))
    end

    let (new_minimum) = _get_minimum_amount(
        amounts_index=1, 
        amounts_len=amounts_len, 
        amounts=amounts, 
        minimum=[amounts]
    )
    return (minimum=new_minimum)
end

@view
func _get_minimum_amount{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        amounts_index : felt,
        amounts_len : felt,
        amounts : Uint256*,
        minimum : Uint256
    ) -> (
        new_minimum : Uint256
    ):
    alloc_locals
    if amounts_index == amounts_len:
        return (new_minimum=minimum)
    end

    let (check) = uint256_le(minimum, amounts[amounts_index])

    if check == TRUE:
        tempvar new_minimum = minimum
    else:
        tempvar new_minimum = amounts[amounts_index]
    end

    let (new_minimum) = _get_minimum_amount(
        amounts_index=amounts_index + 1,
        amounts_len=amounts_len,
        amounts=amounts,
        minimum=new_minimum
    )

    return (new_minimum=new_minimum)
end

func get_token_balances{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (
        balances_len : felt,
        balances : Uint256*
    ):
    alloc_locals
    let (tokens_len, tokens) = get_tokens()
    let (local balances : Uint256*) = alloc()
    
    if tokens_len == 0:
        return (balances_len=tokens_len, balances=balances)
    end

    _get_token_balances(
        tokens_index=0, 
        tokens_len=tokens_len, 
        tokens=tokens, 
        balances=balances
    )


    return (balances_len=tokens_len, balances=balances)
end

func _get_token_balances{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        tokens_index : felt,
        tokens_len : felt, 
        tokens : felt*,
        balances : Uint256*
    ):
    if tokens_index == tokens_len:
        return ()
    end

    let (contract_address) = get_contract_address()
    let (balance) = IERC20.balanceOf(contract_address=tokens[tokens_index], account=contract_address)
    assert balances[tokens_index] = balance

    _get_token_balances(
        tokens_index=tokens_index + 1, 
        tokens_len=tokens_len, 
        tokens=tokens, 
        balances=balances
    )
    return()
end

@view
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

    let (contract_address) = get_contract_address()
    let (reserve) = _token_reserves.read(token=tokens[tokens_index])
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

    IERC20.transfer(contract_address=tokens[amounts_index], recipient=owner, amount=amounts[amounts_index])

    _distribute_amounts(
        amounts_index=amounts_index + 1,
        amounts_len=amounts_len,
        amounts=amounts,
        owner=owner,
        tokens=tokens
    )
    return ()
end

