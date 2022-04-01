"""ERC20.cairo test file."""
import os

import pytest
from starkware.starknet.testing.starknet import Starknet
from starkware.starkware_utils.error_handling import StarkException
from utils.Signer import Signer

ERC20_CONTRACT_FILE = os.path.join("contracts", "ERC20.cairo")
signer = Signer(123456789)


@pytest.mark.asyncio
async def test_erc20():
    """Test ERC20 token."""
    starknet = await Starknet.empty()
    erc20_contract = await starknet.deploy(
        source=ERC20_CONTRACT_FILE,
        constructor_calldata=[123, 123, 18, 0, 1000 * 10**18, signer.public_key],
    )

    execution_info = await erc20_contract.balanceOf(signer.public_key).call()
    assert execution_info.result == ((0, 1000 * 10**18),)
