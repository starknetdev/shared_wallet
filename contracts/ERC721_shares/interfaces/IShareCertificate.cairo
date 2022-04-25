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

    func get_shares(
            owner: felt
        ) -> (
            share: Uint256
        ):
    end

    func get_total_shares()
        -> (
            total_shares: Uint256
        ):
    end

    func mint(
            owner: felt,
            share: Uint256,
            fund: felt
        ):
    end

    func burn(
            owner: felt
        ):
    end

    func increase_shares(
            owner: felt,
            amount: Uint256
        ):
    end

    func decrease_shares(
            owner: felt,
            amount: Uint256
        ):
    end
end