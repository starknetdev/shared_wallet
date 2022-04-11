%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IShareCertificate:

    func mint(
            owner: felt,
            token: felt,
            share: Uint256
        ):
    end

    func burn(
            owner: felt,
            token: felt
        ):
    end
end