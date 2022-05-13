## SPDX-License-Identifier: AGPL-3.0-or-later

%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_block_timestamp
from starkware.cairo.common.math_cmp import is_le

from contracts.interfaces.IGovernor import IGovernor

## @title Example counter task.
## @description Incrementable counter.
## @author Peteris <github.com/Pet3ris>

#############################################
##                 STORAGE                 ##
#############################################

@storage_var
func _governor() -> (res: felt):
end

@storage_var
func _proposal_ids_len() -> (res: felt):
end

@storage_var
func _proposal_ids(index: felt) -> (res: felt):
end

@storage_var
func _execution_params_len(proposal_id: felt) -> (res: felt):
end

@storage_var
func _execution_params(proposal_id: felt, index: felt) -> (execution_param: felt):
end

@storage_var
func __lastExecuted() -> (lastExecuted: felt):
end

#############################################
##             STORAGE HELPERS             ##
#############################################

@external
func store_proposal_ids{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        proposal_id: felt
    ):
    let (proposal_count) = _proposal_ids_len.read()
    _proposal_ids.write(index=proposal_count, value=proposal_id)
    _proposal_ids_len.write(proposal_count + 1)
    return ()
end


@external
func store_execution_params{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        proposal_id: felt,
        execution_params_len: felt,
        execution_params: felt*
    ):

    _execution_params_len.write(proposal_id, execution_params_len)

    _store_execution_params(
        proposal_id=proposal_id,
        execution_params_index=0,
        execution_params_len=execution_params_len,
        execution_params=execution_params
    )

    return ()
end

func _store_execution_params{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        proposal_id: felt,
        execution_params_index: felt,
        execution_params_len: felt,
        execution_params: felt*
    ):
    if execution_params_index == execution_params_len:
        return ()
    end

    _execution_params.write(
        proposal_id=proposal_id,
        index=execution_params_index,
        value=execution_params[execution_params_index]
    )

    _store_execution_params(
        proposal_id=proposal_id,
        execution_params_index=execution_params_index + 1,
        execution_params_len=execution_params_len,
        execution_params=execution_params
    )

    return ()
end

#############################################
##                 GETTERS                 ##
#############################################
@view
func lastExecuted{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (lastExecuted: felt):
    let (lastExecuted) = __lastExecuted.read()
    return (lastExecuted)
end

#############################################
##               CONSTRUCTOR               ##
#############################################

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr : felt}(
        governor: felt):
    _governor.write(governor)
    return ()
end

#############################################
##                  TASK                   ##
#############################################

@view
func probeTask{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (taskReady: felt):
    alloc_locals

    let (lastExecuted) = __lastExecuted.read()
    let (block_timestamp) = get_block_timestamp()
    let deadline = lastExecuted + 60
    let (taskReady) = is_le(deadline, block_timestamp)

    return (taskReady=taskReady)
end

@external
func executeTask{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> ():
    # One could call `probeTask` here; it depends
    # entirely on the application.

    let (proposal_ids_len) = _proposal_ids_len.read()

    _finalize_proposal(
        proposal_ids_index=0,
        proposal_ids_len=proposal_ids_len
    )

    let (block_timestamp) = get_block_timestamp()
    __lastExecuted.write(block_timestamp)
    return ()
end

func _finalize_proposal{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        proposal_ids_index: felt,
        proposal_ids_len: felt
    ):
    alloc_locals
    if proposal_ids_index == proposal_ids_len:
        return ()
    end

    let (proposal_id) = _proposal_ids.read(proposal_ids_index)

    let (local governor_contract) = _governor.read()

    let (execution_params_len) = _execution_params_len.read(proposal_id)

    let (execution_params) = get_execution_params(
        proposal_id=proposal_id,
        execution_params_len=execution_params_len
    )

    IGovernor.finalize_proposal(
        contract_address=governor_contract,
        proposal_id=proposal_id,
        execution_params_len=execution_params_len,
        execution_params=execution_params
    )

    _finalize_proposal(
        proposal_ids_index=proposal_ids_index + 1,
        proposal_ids_len=proposal_ids_len
    )
    return ()
end

func get_execution_params{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        proposal_id: felt,
        execution_params_len: felt
    ) -> (execution_params: felt*):
    alloc_locals
    let (execution_params) = alloc()
    
    _get_execution_params(
        proposal_id=proposal_id,
        execution_params_index=0,
        execution_params_len=execution_params_len,
        execution_params=execution_params
    )
    return (execution_params=execution_params)
end

func _get_execution_params{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        proposal_id: felt,
        execution_params_index: felt,
        execution_params_len: felt,
        execution_params: felt*
    ):
    if execution_params_index == execution_params_len:
        return ()
    end

    let (execution_param) = _execution_params.read(proposal_id, execution_params_index)

    assert execution_params[execution_params_index] = execution_param

    _get_execution_params(
        proposal_id=proposal_id,
        execution_params_index=execution_params_index + 1,
        execution_params_len=execution_params_len,
        execution_params=execution_params
    )
    return ()
end
