%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IShareCertificate:

    func mint(
            owner: felt,
            share: Uint256
        ):
    end
