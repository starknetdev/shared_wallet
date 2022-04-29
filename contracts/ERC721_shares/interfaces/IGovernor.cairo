%lang starknet

from contracts.ERC721_shares.lib.eth_address import EthAddress
from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IGovernor:
    func finalize_proposal(
            proposal_id : felt, execution_params_len : felt, execution_params : felt*):
    end

end
