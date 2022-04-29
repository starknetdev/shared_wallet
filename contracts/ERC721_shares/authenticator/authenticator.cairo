%lang starknet
from starkware.starknet.common.syscalls import call_contract
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin

# Forwards `data` to `target` without verifying anything.
@external
func execute{syscall_ptr : felt*, range_check_ptr}(
        to : felt, function_selector : felt, calldata_len : felt, calldata : felt*) -> ():
    # TODO: Actually verify the signature

    # Call the contract
    call_contract(
        contract_address=to,
        function_selector=function_selector,
        calldata_size=calldata_len,
        calldata=calldata)

    return ()
end

# func is_valid_signature{
#         syscall_ptr : felt*, 
#         pedersen_ptr : HashBuiltin*,
#         range_check_ptr, 
#         ecdsa_ptr: SignatureBuiltin*
#     }(
#         hash: felt,
#         signature_len: felt,
#         signature: felt*
#     ) -> ():
#     let (_public_key) = Account_public_key.read()

#     # This interface expects a signature pointer and length to make
#     # no assumption about signature validation schemes.
#     # But this implementation does, and it expects a (sig_r, sig_s) pair.
#     let sig_r = signature[0]
#     let sig_s = signature[1]

#     verify_ecdsa_signature(
#         message=hash,
#         public_key=_public_key,
#         signature_r=sig_r,
#         signature_s=sig_s)

#     return ()
# end
