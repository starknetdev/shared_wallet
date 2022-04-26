%lang starknet

from contracts.governance.GovernanceToken import get_past_total_supply
from contracts.governance.interfaces.IGovernanceToken import IGovernanceToken

#
# Storage variables
#

@storage_var
func token() -> (res: felt):
end

@storage_var
func _quorum_numerator() -> (res: felt):
end

#
# Events
#

@event
func QuorumNumeratorUpdated(old_quorum_numerator : felt, new_quorum_numerator):
end

#
# Constructor
#

@constructor
func constructor{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(quorum_numerator_value : felt):
    _update_quorum_numerator(quorum_numerator_value)
    return ()
end

#
# Getters
#

@view
func quorum_numerator{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (value : felt):
    let (quorum_numerator) = _quorum_numerator.read()
    return (value=quorum_numerator)
end

@view
func quorum_denominator{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (value : felt):
    return (value=100)
end

@view
func quorum{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(block_number : felt) -> (value : felt):
    let (token) = token.read()
    let (past_votes) = IGovernanceToken.get_past_total_supply(
        contract_address=token,
        block_number=block_number
    )
    let (quorum_numerator) = quorum_numerator()
    let (quorum_denominator) = quorum_denominator()
    let (new_quorum_numerator) = past_votes * quorum_numerator
    let (quorum) = new_quorum_numerator / quorum_denominator
    return (value=quorum)
end

#
# Actions
#

func _update_quorum_numerator{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(new_quorum_numerator : felt):
    let (quorum_denominator) = quorum_denominator()
    with_attr error_message("Governor Votes Quorum Fraction: Quorum Numerator over quorum denominator"):
        assert_le(new_quorum_numerator, quorum_denominator)
    end
    let (old_quorum_numerator) = _quorum_numerator.read()
    _quorum_numerator.write(new_quorum_numerator)

    QuorumNumeratorUpdated.emit(old_quorum_numerator, new_quorum_numerator)
    return ()
end