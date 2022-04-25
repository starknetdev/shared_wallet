%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IShareCertificate:

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

    func get_total_shares(
            fund: felt
        ) -> (
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
            token_id: Uint256
        ):
    end

    func increase_shares(
            token_id: Uint256,
            amount: Uint256
        ):
    end

    func decrease_shares(
            token_id: Uint256,
            amount: Uint256
        ):
    end
end