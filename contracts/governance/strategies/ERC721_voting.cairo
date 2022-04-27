%lang starknet

from starkware.cairo.common.uint256 import Uint256
from contracts.governance.lib.eth_address import EthAddress

from contracts.governance.interfaces.IVotingCertificate import IVotingCertificate

# Returns a voting power of 1 for every address it is queried with.
@view
func get_voting_power{range_check_ptr}(
        timestamp : felt, address : EthAddress, params_len : felt, params : felt*) -> (
        voting_power : Uint256):
    return (Uint256(1, 0))
end
