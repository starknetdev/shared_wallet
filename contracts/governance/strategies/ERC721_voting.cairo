%lang starknet

from starkware.cairo.common.uint256 import Uint256
from contracts.governance.lib.eth_address import EthAddress

from contracts.governance.interfaces.IVotingCertificate import IVotingCertificate

# Returns a voting power of 1 for every address it is queried with.
@view
func get_voting_power{syscall_ptr : felt*, range_check_ptr}(
        timestamp : felt, address : EthAddress, params_len : felt, params : felt*) -> (
        voting_power : Uint256):
    let vote_certificate = params[0]
    let fund = params[1]
    let (token_id: Uint256) = IVotingCertificate.get_certificate_id(
        contract_address=vote_certificate,
        owner=address.value,
        fund=fund
    )
    let (shares) = IVotingCertificate.get_shares(
        contract_address=vote_certificate,
        token_id=token_id
    )
    return (voting_power=shares)
end
