%lang starknet

@contract_interface
namespace IGovernanceToken:
    func get_past_total_supply(
            block_number: felt
        ) -> (votes: felt):
    end
end