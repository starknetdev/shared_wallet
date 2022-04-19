%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IPriceAggregator:

    func get_data(asset_type: felt) -> (value: Uint256):
    end
end