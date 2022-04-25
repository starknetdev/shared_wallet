%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin

#
# Structs
#

struct Checkpoint:
   member from_block: felt
   member votes: felt
end 

#
# Storage variables
#

@storage_var
func _checkpoints() -> (Checkpoint):
end

#
# Actions
#

@view
func checkpoints{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        account : felt,
        pos : felt
    ) -> (Checkpoint : Checkpoint):
    return (
