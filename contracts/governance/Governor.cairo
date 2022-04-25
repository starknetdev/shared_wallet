%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_le, assert_lt
from starkware.starknet.common.syscalls import call_contract, get_caller_address, get_contract_address


#
# Structs
#

struct ProposalCore:
    member vote_start: felt
    member vote_end: felt
    member executed: felt
    member cancelled: felt
end

#
# Storage var
#

@storage_var
func name() -> (res: felt):
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
        name : felt
    ):
    name.write(name)
    return ()
end

#
# Actions
#

@view
func state{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        proposal_id : felt
    ) -> (
        proposal_state : felt
    ):
    if proposal.executed == TRUE:
        return ProposalState.executed

    if proposal.cancelled == TRUE:
        return ProposalState.cancelled
    
    let (snapshot) = 

func proposal_snapshot{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        proposal_id : felt
    ):
    return (_proposals[proposal_id].vote_start.get_deadline())
end

@external
func propose{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }():
    let (caller_address) = get_caller_address()
    with_attr error_message("Governor: proposer votes below proposal threshold")
        assert_le(proposal_threshold.read(), get_votes(caller_address))
    end
    return ()
end

@view
func get_votes{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        account : felt,
        block_number : felt
    ):
    
