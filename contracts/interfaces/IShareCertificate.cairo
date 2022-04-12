%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IShareCertificate:

    func get_certificate_id(
            owner: felt
        ) -> (
            certificate_id: Uint256
        ):
    end

    func mint(
            owner: felt,
            share: Uint256
        ):
    end

    func burn(
            owner: felt
        ):
    end
end