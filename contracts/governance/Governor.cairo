%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_le, assert_lt
from starkware.starknet.common.syscalls import call_contract, get_caller_address, get_contract_address
from starkware.cairo.common.hash_state import (
    hash_init, hash_finalize, hash_update, hash_update_single
)


from contracts.utils.constants import FALSE, TRUE

from starkware.starknet.common.syscalls import (
    get_block_number,
    get_block_timestamp,
)

#
# Events
#

@event
func SubmitProposal(
        proposal_id : felt,
        owner : felt, 
        tx_index_len : felt, 
        targets : felt*,
        function_selectors : felt*,
        calldatas : felt*,
        snapshot : felt,
        deadline : felt,
        description : felt
    ):
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
        name : felt,
        voting_delay : felt,
        voting_period : felt
    ):
    name.write(name)
    return ()
end

#
# Actions
#

@view
func proposal_state{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        proposal_id : felt
    ) -> (
        proposal_state : felt
    ):
    if proposal.executed == TRUE:
        return (proposal_state=0)
    end

    if proposal.cancelled == TRUE:
        return (proposal_state=1)
    end
    
    let (snapshot) = proposal_snapshot(proposal_id)

    with_attr error_message("Governor: Unknown proposal id"):
        assert snapshot = 0
    end

    let (block_number) = get_block_number()
    if assert_le(block_number, snapshot) == TRUE:
        return (proposal_state=2)
    end

    let (deadline) = proposal_deadline()

    if assert_le(block_number, deadline) == TRUE:
        return (proposal_state=3)
    end

    if (quorum_reached(proposal_id) + _vote_succeeded(proposal_id)) == 2:
        return (proposal_state=4)
    else:
        return (proposal_state=5)
    end
    return ()
end

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

    with_attr error_message("Governor: Invalid proposal length"):
        assert targets_len = function_selectors_len
    end

    with_attr error_message("Governor: Invalid proposal length"):
        assert targets_len = calldatas_len
    end

    with_attr error_message("Governor: Empty proposal"):
        assert_le(0, targets_len)
    end

    let (proposals_index) = _proposals_count.read()
    let (check_start) = _proposals.read(
        index=proposal_index,
        field=ProposalCore.vote_start
    )
    with_attr error_message("Governor: Proposal already exists"):
        assert check_start = 0
    end

    store_proposal_transaction(
        tx_index=0,
        tx_index_len=calldatas_len,
        to=targets[0],
        function_selector=function_selectors[0],
        calldata=calldatas[0],
        proposal_index=proposals_count
    )

    let (block_number) = get_block_number()

    let (snapshot) = block_number + voting_delay
    let (deadline) = snapshot + voting_period

    _proposals.write(
        index=proposals_index,
        field=ProposalCore.vote_start,
        res=snapshot
    )

    _proposals.write(
        index=proposals_index,
        field=ProposalsCore.vote_end,
        res=deadline
    )

    let (caller) = get_caller_address()
    SubmitProposal.emit(
        proposal_id=proposals_count,
        owner=caller, 
        tx_index_len=tx_index_len, 
        targets=targets,
        function_selectors=function_selectors,
        calldatas=calldatas,
        snapshot=snapshot,
        deadline=deadline,
        description=description
    )

    _proposals_count.write(proposals_count + 1)

    return ()
end

func store_proposal_transaction{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        tx_index : felt,
        tx_index_len : felt,
        to : felt,
        function_selector : felt,
        calldata_len : felt,
        calldata : felt*,
        proposal_index : felt
    ):
    alloc_locals
    require_owner()
    if tx_index == tx_index_len:
        return ()
    end


    # Store the tx descriptor
    _proposal_transactions.write(proposal_index=proposal_index, tx_index=tx_index, field=Transaction.to, value=to)
    _proposal_transactions.write(proposal_index=proposal_index, tx_index=tx_index, field=Transaction.function_selector, value=function_selector)
    _proposal_transactions.write(proposal_index=proposal_index, tx_index=tx_index, field=Transaction.calldata_len, value=calldata_len)

    # Recursively store the tx calldata
    _set_proposal_transaction_calldata(
        tx_index=tx_index,
        calldata_index=0,
        calldata_len=calldata_len,
        calldata=calldata,
    )

    store_proposal_transaction(
        tx_index=tx_index + 1,
        tx_index_len=tx_index_len,
        to=targets[tx_index + 1],
        function_selector=function_selectors[tx_index + 1],
        calldata=calldatas[tx_index + 1],
        proposal_index=proposal_index
    )

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

func execute_proposal{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (:
    alloc_locals
    require_owner()
    let (responses: felt*) = alloc()

    _execute(tx_index=0, tx_index_len=tx_index_len)

    response_len=response.retdata_size, response=response.retdata

    return (responses_len=responses_len, responses=responses)
end

func _execute{
        syscall_ptr : felt*
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        tx_index : felt,
        tx_index_len : felt
    ) -> (
        response_len : felt,
        response : felt*
    ):
    if tx_index == tx_index_len:

        return ()
    end

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

    let response = call_contract(
        contract_address=tx.to,
        function_selector=tx.function_selector,
        calldata_size=tx_calldata_len,
        calldata=calldata
    )

    assert reponses[tx_index] = response

    _execute(
        tx_index=tx_index + 1,
        tx_index_len=tx_index_len
    )

    return ()
end

func _cancel{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        proposal_id : felt
    ):
    let (status) = proposal_state(proposal_id)

    with_attr error_message("Governor: proposal not active"):
        assert status != ProposalState.cancelled
        assert status != ProposalState.expired
        assert status != ProposalState.executed
    end

    _proposals.write(index=proposal_id, field=ProposalCore.cancelled, res=TRUE)

    ProposalCancelled.emit(proposal_id=proposal_id)
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

func _cast_vote{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        proposal_id : felt,
        account : felt,
        support : felt,
        reason : felt,
        params : felt
    ) -> (weight : felt):
    let (vote_start) _proposals.read(proposal_id)
    