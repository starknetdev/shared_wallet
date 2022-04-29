%lang starknet

from contracts.ERC721_shares.lib.eth_address import EthAddress
from starkware.cairo.common.uint256 import Uint256

struct Vote:
    member choice : felt
    member voting_power : Uint256
end
