%lang starknet

@contract_interface
namespace IGovernor:
    func proposal_snapshot(
            proposal_id : felt
        ) -> (bool : felt):
    end
end