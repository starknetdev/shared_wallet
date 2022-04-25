%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_le, assert_lt
from starkware.starknet.common.syscalls import call_contract, get_caller_address, get_contract_address
from starkware.cairo.common.hash_state import (
    hash_init, hash_finalize, hash_update, hash_update_single
)


from contracts.utils.constants import FALSE, TRUE


#
# Events
#

@event
func SubmitProposal(owner : felt, tx_index : felt, to : felt):
end

@event
func ExecuteTransaction(owner : felt, tx_index : felt):
end

#
# Structs
#

struct ProposalCore:
    member vote_start: felt
    member vote_end: felt
    member executed: felt
    member cancelled: felt
end

struct ProposalTransaction:
    member to: felt
    member function_selector: felt
    member calldata_len: felt
    member executed: felt
end

#
# Storage var
#

@storage_var
func name() -> (res: felt):
end

@storage_var
func _proposals_count() -> (res: felt):
end

@storage_var
func _proposals(index : felt, field : felt) -> (res : felt):
end

@storage_var
func _proposal_transactions(proposal_index : felt, tx_index : felt, field : felt) -> (res : felt):
end

@storage_var
func _proposal_transaction_calldata(tx_index : felt, calldata_index : felt) -> (res : felt):
end

#
# Guards
#

func require_owner{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }():
    let (caller_address) = get_caller_address()
    let (balance) = IGovernanceToken.balanceOf(caller_address)
    let (check_balance) = uint256_lt(0, balance)
    with_attr error_message("Governance: Only owner can submit proposal"):
        assert check_balance = TRUE
    end
    return ()
end

func only_governance{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }():
    let (caller_address) = get_caller_address()
    let (contract_address) = get_contract_address()
    with_attr error_message("Governor: Only governance"):
        assert caller_address = contract_address
    end
    return ()
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
    }(
        targets_len : felt,
        targets : felt*,
        function_selectors_len : felt,
        function_selectors : felt*,
        calldatas_len : felt,
        calldatas : felt*,
        description : felt
    ):
    require_owner()
    let (block_number) = get_block_number()
    let (proposals_count) = _proposals_count()

    store_proposal_transaction(
        tx_index=0,
        to=[targets],
        function_selector=[function_selectors],
        calldata=[calldatas],
        proposal_index=proposals_count
    )



func store_proposal_transaction{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        tx_index : felt,
        to : felt,
        function_selector : felt,
        calldata_len : felt,
        calldata : felt*,
        proposal_index : felt
        ):
    alloc_locals
    require_owner()



    # Store the tx descriptor
    _proposal_transactions.write(proposal_index=proposal_index, tx_index=tx_index, field=Transaction.to, value=to)
    _proposal_transactions.write(proposal_index=proposal_index, tx_index=tx_index, field=Transaction.function_selector, value=function_selector)
    _proposal_transactions.write(proposal_index=proposal_index, tx_index=tx_index, field=Transaction.calldata_len, value=calldata_len)

    # Recursively store the tx calldata
    _set_transaction_calldata(
        tx_index=tx_index,
        calldata_index=0,
        calldata_len=calldata_len,
        calldata=calldata,
    )

    # Emit event & update tx count
    let (caller) = get_caller_address()
    SubmitProposal.emit(owner=caller, tx_index=tx_index, to=to)
    _next_tx_index.write(value=tx_index + 1)

    return ()
end

func _set_proposal_transaction_calldata{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }(
        tx_index : felt,
        calldata_index : felt,
        calldata_len : felt,
        calldata : felt*,
    ):
    if calldata_index == calldata_len:
        return ()
    end

     # Write the current iteration to storage
    _transaction_calldata.write(
        tx_index=tx_index,
        calldata_index=calldata_index,
        value=[calldata],
    )

    # Recursively write the rest
    _set_transaction_calldata(
        tx_index=tx_index,
        calldata_index=calldata_index + 1,
        calldata_len=calldata_len,
        calldata=calldata + 1,
    )
    return ()
end

func _execute{
        syscall_ptr : felt*
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(tx_index : felt) -> (
        response_len : felt,
        response : felt*
    ):
    require_owner()
    require_tx_exists(tx_index=tx_index)
    require_not_executed(tx_index=tx_index)

    let (tx, tx_calldata_len, tx_calldata) = get_transaction(tx_index=tx_index)

    let (votes) = get_votes(tx_index=tx_index)

    # Require minimum votes acquired
    with_attr error_message("Governor: Proposal needs more votes"):
        assert_le(required_votes, votes)
    end

    _proposal_transactions.write(
        tx_index=tx_index,
        field=Transaction.executed,
        value=TRUE
    )

    let (caller) = get_caller_address()
    ExecuteTransaction.emit(owner=caller, tx_index=tx_index)

    # Actually execute it




@view
func get_votes{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        account : felt,
        block_number : felt
    ):