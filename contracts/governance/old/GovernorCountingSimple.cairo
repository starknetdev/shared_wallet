%lang starknet

from contracts.governance.GovernorVotesQuorumFraction import quorum

#
# Struct
#

namespace VoteType:
    const FOR = 1
    const AGAINST = 2
    const ABSTAIN = 3
end

struct ProposalVote:
    member against_votes: felt
    member for_votes: felt
    member abstain_votes: felt
    member has_voted: felt
end

#
# Storage variables
#

@storage_var
func _proposal_votes(proposal_id : felt) -> (proposal_vote : ProposalVote):
end

#
# Getters
#

@view
func has_voted{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        proposal_id : felt,
        account : felt
    ) -> (bool : felt):
    let (proposal_vote) = _proposal_votes.read(proposal_id)
    return (proposal_vote.has_voted)
end

@view
func proposal_votes{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(proposal_id : felt) -> (
        against_votes : felt,
        for_votes : felt,
        abstain_votes : felt
    ):
    let (proposal_vote) = _proposal_votes.read(proposal_id)
    return (
        against_votes=proposal_vote.against_votes,
        for_votes=proposal_vote.for_votes,
        abstain_votes=proposal_vote.abstain_votes
    )
end

func _quorum_reached{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(proposal_id : felt) -> (bool : felt):
    let (proposal_vote) = _proposal_votes.read(proposal_id)
    let (snapshot) = proposal_snapshot(proposal_id)
    let (quorum) = quorum(snapshot)
    let (check) = assert_le(quorum, proposal_vote.for_votes + proposal_vote.abstain_votes)
    return (bool=check)
end

func _vote_succeeded{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(proposal_id : felt) -> (bool : felt):
    let (proposal_vote) = _proposal_votes.read(proposal_id)
    let (check) = assert_lt(proposal_vote.for_votes, proposal_vote.against_votes)
    return (check)
end

func _count_vote{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        proposal_id : felt,
        account : felt,
        support : felt,
        weight : felt,
        params : felt
    ):
    let (proposal_vote) = _proposal_votes.read(proposal_id)
    with_attr error_message("Gorvernor Voting Simple: Vote already cast"):
        assert proposal_vote.has_voted = FALSE
    end
    assert proposal_vote.has_voted = TRUE

    if support == VoteType.Against:
        assert proposal_vote.against_votes = proposal_vote.against_votes + weight
    end
    if support == VoteType.For:
        assert proposal_vote.for_votes = proposal_vote.


