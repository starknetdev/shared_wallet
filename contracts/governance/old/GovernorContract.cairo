%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin

#
# Storage variables
#

@storage_var
func voting_delay() -> (res: felt):
end

@storage_var
func voting_period() -> (res: felt):
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
        token : felt,
        timelock_controller : felt,
        quorum_percentage : felt,
        voting_period : felt,
        voting_delay : felt
    ):
    voting_delay.write(voting_delay)
    voting_period.write(voting_period)
    return ()
end