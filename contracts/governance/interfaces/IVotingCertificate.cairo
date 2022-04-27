%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IVotingCertificate:

    func get_certificate_id(
            owner: felt,
            fund: felt
        ) -> (
            certificate_id: Uint256
        ):
    end

    func get_shares(
            token_id: Uint256
        ) -> (
            share: Uint256
        ):
    end
end