# SPDX-License-Identifier: MIT
# OpenZeppelin Contracts for Cairo v0.1.0 (token/erc721/ERC721_Mintable_Burnable.cairo)

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.uint256 import Uint256

from openzeppelin.token.erc721.library import (
    ERC721_name,
    ERC721_symbol,
    ERC721_balanceOf,
    ERC721_ownerOf,
    ERC721_getApproved,
    ERC721_isApprovedForAll,
    ERC721_tokenURI,

    ERC721_initializer,
    ERC721_approve, 
    ERC721_setApprovalForAll, 
    ERC721_transferFrom,
    ERC721_safeTransferFrom,
    ERC721_mint,
    ERC721_burn,
    ERC721_only_token_owner,
    ERC721_setTokenURI
)

from openzeppelin.introspection.ERC165 import ERC165_supports_interface

from openzeppelin.access.ownable import (
    Ownable_initializer,
    Ownable_only_owner
)

from starkware.starknet.common.syscalls import (
    get_block_number,
    get_block_timestamp,
)

#
# Struct
#

struct Checkpoint:
    member from_block: felt
    member votes: felt
end

#
# Storage variables
#

@storage_var
func _checkpoints_len() -> (res: felt):
end

@storage_var
func _total_checkpoints() -> (res: Checkpoint*):
end

@storage_var
func _account_checkpoints(account:felt) -> (res: Checkpoint*):
end

@storage_var
func _checkpoints(account: felt, index: felt) -> (res: Checkpoint):
end

@storage_var
func _delegates(account : felt) -> (delegate : felt):
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
        name: felt,
        symbol: felt,
        owner: felt
    ):
    ERC721_initializer(name, symbol)
    Ownable_initializer(owner)
    return ()
end

#
# Getters
#

@view
func supportsInterface{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(interfaceId: felt) -> (success: felt):
    let (success) = ERC165_supports_interface(interfaceId)
    return (success)
end

@view
func name{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (name: felt):
    let (name) = ERC721_name()
    return (name)
end

@view
func symbol{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (symbol: felt):
    let (symbol) = ERC721_symbol()
    return (symbol)
end

@view
func balanceOf{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(owner: felt) -> (balance: Uint256):
    let (balance: Uint256) = ERC721_balanceOf(owner)
    return (balance)
end

@view
func ownerOf{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(tokenId: Uint256) -> (owner: felt):
    let (owner: felt) = ERC721_ownerOf(tokenId)
    return (owner)
end

@view
func getApproved{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(tokenId: Uint256) -> (approved: felt):
    let (approved: felt) = ERC721_getApproved(tokenId)
    return (approved)
end

@view
func isApprovedForAll{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(owner: felt, operator: felt) -> (isApproved: felt):
    let (isApproved: felt) = ERC721_isApprovedForAll(owner, operator)
    return (isApproved)
end

@view
func tokenURI{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*, 
        range_check_ptr
    }(tokenId: Uint256) -> (tokenURI: felt):
    let (tokenURI: felt) = ERC721_tokenURI(tokenId)
    return (tokenURI)
end

@view
func checkpoints{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        account : felt,
        pos : felt
    ) -> (checkpoint : Checkpoint):
    let (checkpoint) = _checkpoints.read(account, pos)
    return (checkpoint)
end

@view
func num_checkpoints{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        account : felt
    ) -> (checkpoints_len : felt):
    let (checkpoints_len) = _checkpoints_len.read()
    return (checkpoints_len)
return

@view
func delegates{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(account : felt) -> (delegate : felt):
    let (delegate) = _delegates.read(account)
    return (delegate)
end

@view
func get_votes{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(account : felt) -> (votes : felt):
    let (pos) = _checkpoints_len.read()
    if pos == 0:
        return (votes=0)
    else:
        let (checkpoint) = _checkpoints.read(
            account=account,
            index=pos - 1
        )
        return (votes=checkpoint.votes)
    end
end

@view
func get_past_votes{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        account : felt,
        block_number : felt
    ) -> (votes : felt):
    let (current_block) = get_block_number()
    with_attr error_message("ERC20Votes: Block not yet mined"):
        assert_lt(block_number, current_block)
    end
    let (account_checkpoints) = _account_checkpoints.read(account)
    let (votes) = _checkpoints_lookup(account_checkpoints, block_number)
    return (votes)
end

@view
func get_past_total_supply{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        block_number : felt
    ) -> (votes : felt):
    let (current_block) = get_block_number()
    with_attr error_message("ERC20Votes: Block not yet mined"):
        assert_lt(block_number, current_block)
    end
    let (total_checkpoints) = _total_checkpoints.read()
    let (votes) = _checkpoints_lookup(total_checkpoints, block_number)
    return (votes=votes)
end

#
# Externals
#

@external
func approve{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(to: felt, tokenId: Uint256):
    ERC721_approve(to, tokenId)
    return ()
end

@external
func setApprovalForAll{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*, 
        range_check_ptr
    }(operator: felt, approved: felt):
    ERC721_setApprovalForAll(operator, approved)
    return ()
end

@external
func transferFrom{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        from_: felt, 
        to: felt, 
        tokenId: Uint256
    ):
    ERC721_transferFrom(from_, to, tokenId)
    return ()
end

@external
func safeTransferFrom{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        from_: felt, 
        to: felt, 
        tokenId: Uint256,
        data_len: felt, 
        data: felt*
    ):
    ERC721_safeTransferFrom(from_, to, tokenId, data_len, data)
    return ()
end

@external
func setTokenURI{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(tokenId: Uint256, tokenURI: felt):
    Ownable_only_owner()
    ERC721_setTokenURI(tokenId, tokenURI)
    return ()
end

@external
func mint{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(to: felt, tokenId: Uint256):
    Ownable_only_owner()
    ERC721_mint(to, tokenId)
    return ()
end

@external
func burn{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(tokenId: Uint256):
    ERC721_only_token_owner(tokenId)
    ERC721_burn(tokenId)
    return ()
end

func _checkpoints_lookup{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        checkpoints : Checkpoint*,
        block_number : felt
    ) -> (value : felt):
    let (high) = _checkpoints_len
    let (low) = 0
    if assert_lt(low, high) == TRUE:
        let (mid) = (low + high) / 2
        let (mid_checkpoint) = _checkpoints.read(mid)
        if assert_lt(mid_checkpoint.from_block, block_number):
            assert high = mid
        else:
            assert low = mid + 1
        end
    end
    if high == 0:
        return (value=0)
    else:
        let (checkpoint) = _checkpoints.read(high - 1)
        return (value=checkpoints.votes)
    end
    return ()
end


func _move_voting_power{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        src : felt,
        dst : felt,
        amount : Uint256
    ):
    if (src != dst) * assert_lt(0, amount):
        if (src != address(0)):
            let (old_weight, new_weight) = _write_checkpoint(_checkpoints[src], _subtract, amount)
        end
        if (dst != address()):
            let (old_weight, new_weight) = _write_checkpoint(_checkpoints[dst], _add, amount)
        end
    end
end

func _write_checkpoint_add{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        checkpoints_len : felt,
        checkpoints : Checkpoint*,
        delta : felt
    ) -> (
        old_weight : felt,
        new_weight : felt
    ):
    let (pos) = checkpoints.length
    if pos == 0:
        let (old_weight) = 0
    else:
        let (old_weight) = checkpoints[pos - 1].votes
    end
    let (new_weight) = old_weight + delta
    let (block_number) = get_block_number()
    let (data) = Checkpoint(
        from_block=block_number, 
        votes=new_weight
    )
    checkpoints.write(checkpoints_len - 1, data)
    return (old_weight=old_weight, new_weight=new_weight)
end

func _write_checkpoint_sub{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        checkpoints_len : felt,
        checkpoints : Checkpoint*,
        delta : felt
    ) -> (
        old_weight : felt,
        new_weight : felt
    ):
    let (pos) = checkpoints.length
    if pos == 0:
        let (old_weight) = 0
    else:
        let (old_weight) = checkpoints[pos - 1].votes
    end
    let (new_weight) = old_weight - delta
    let (block_number) = get_block_number()
    let (data) = Checkpoint(
        from_block=block_number, 
        votes=new_weight
    )
    checkpoints.write(checkpoints_len - 1, data)
    return (old_weight=old_weight, new_weight=new_weight)
end