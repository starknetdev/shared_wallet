%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IPriceAggregator:

    func get_data(token: felt) -> (value: Uint256, decimals: felt):
    end
end