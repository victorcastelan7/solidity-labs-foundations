// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;


// ███▓▒░░────────────────────────────────────────────────────────────────────────────░░▒▓███
// ░░      ░░░        ░░  ░░░░  ░░       ░░░  ░░░░░░░░        ░░       ░░░░      ░░░░      ░░
// ▒  ▒▒▒▒▒▒▒▒▒▒▒  ▒▒▒▒▒   ▒▒   ▒▒  ▒▒▒▒  ▒▒  ▒▒▒▒▒▒▒▒  ▒▒▒▒▒▒▒▒  ▒▒▒▒  ▒▒  ▒▒▒▒  ▒▒  ▒▒▒▒  ▒
// ▓▓      ▓▓▓▓▓▓  ▓▓▓▓▓        ▓▓       ▓▓▓  ▓▓▓▓▓▓▓▓      ▓▓▓▓  ▓▓▓▓  ▓▓  ▓▓▓▓  ▓▓  ▓▓▓▓  ▓
// ███████  █████  █████  █  █  ██  ████████  ████████  ████████  ████  ██        ██  ████  █
// ██      ███        ██  ████  ██  ████████        ██        ██       ███  ████  ███      ██
// ███▓▒░░──────────────────────────────── SIMPLE DAO ────────────────────────────────░░▒▓███
                                                                  
/// @notice Minimal timelock interface for the DAO to interact with.
interface ISimpleTimelock {
    function queue(uint256 proposalId) external returns (uint256 eta);
    function execute(uint256 proposalId) external;
}

/// @title SimpleDAO
/// @notice Minimal DAO with proposals, voting, quorum, and timelock hooks (no logic yet).


contract SimpleDAO {


    // ███▓▓▒▒░░░░░────────────────===[  Structs  ]===────────────────░░░░░▒▒▓▓███

    struct Proposal {
        address proposer;
        uint64 startTime; // voting start
        uint64 endTime; // voting end
        uint64 eta; // execution time (from timelock)
        bool executed;
        bool queued;
        uint256 forVotes;
        uint256 againstVotes;
        string description; // optional human-readable text
    }


    // ███▓▓▒▒░░░░░────────────────===[  Storage  ]===────────────────░░░░░▒▒▓▓███

    uint256 private s_proposalCount;
    mapping(uint256 => Proposal) private s_proposals;
    mapping(uint256 => mapping(address => bool)) private s_hasVoted;

    uint256 public immutable i_quorum;
    uint256 public immutable i_votingPeriod; // e.g. in seconds
    ISimpleTimelock public immutable i_timelock;


    // ███▓▓▒▒░░░░░────────────────===[  Events  ]===────────────────░░░░░▒▒▓▓███

    event ProposalCreated(
        uint256 indexed proposalId, address indexed proposer, uint64 startTime, uint64 endTime, string description
    );

    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 weight);

    event ProposalQueued(uint256 indexed proposalId, uint64 eta);

    event ProposalExecuted(uint256 indexed proposalId);


    // ███▓▓▒▒░░░░░────────────────===[  Errors  ]===────────────────░░░░░▒▒▓▓███

    error SimpleDAO__OnlyTimelock();
    error SimpleDAO__InvalidProposal();
    error SimpleDAO__VotingNotActive();
    error SimpleDAO__AlreadyVoted();
    error SimpleDAO__VotingNotEnded();
    error SimpleDAO__ProposalNotSuccessful();
    error SimpleDAO__ProposalAlreadyQueued();
    error SimpleDAO__ProposalAlreadyExecuted();


    // ███▓▓▒▒░░░░░────────────────===[  Constructor  ]===────────────────░░░░░▒▒▓▓███

    constructor(address timelock, uint256 quorum, uint256 votingPeriod) {
        i_timelock = ISimpleTimelock(timelock);
        i_quorum = quorum;
        i_votingPeriod = votingPeriod;
    }


    // ███▓▓▒▒░░░░░────────────────===[  External API  ]===────────────────░░░░░▒▒▓▓███

    /// @notice Create a new proposal.
    /// @param description Human-readable text describing the proposal.
    /// @return proposalId ID of the newly created proposal.
    function propose(string calldata description) external returns (uint256 proposalId) {
        s_proposalCount++;
        proposalId = s_proposalCount;
        uint64 startTime = uint64(block.timestamp);
        uint64 endTime = uint64(block.timestamp + i_votingPeriod);

        s_proposals[proposalId] = Proposal({
            proposer: msg.sender,
            startTime: startTime, // voting start
            endTime: endTime, // voting end
            eta: 0, // execution time (from timelock)
            executed: false,
            queued: false,
            forVotes: 0,
            againstVotes: 0,
            description: description // optional human-readable text
        });

        emit ProposalCreated(proposalId, msg.sender, startTime, endTime, description);

        return proposalId;
    }

    /// @notice Cast a vote on a proposal.
    /// @param proposalId ID of the proposal.
    /// @param support true if voting for, false if voting against.
    function vote(uint256 proposalId, bool support) external {
        // Voting power
        uint256 voterWeight = 1;
        Proposal storage proposal = s_proposals[proposalId];

        // Verify proposal is valid
        if (proposalId > s_proposalCount || proposalId == 0) revert SimpleDAO__InvalidProposal();

        // Verify voting window is open
        if (block.timestamp > proposal.endTime || block.timestamp < proposal.startTime) {
            revert SimpleDAO__VotingNotActive();
        }

        // Verify caller has not previously voted
        if (s_hasVoted[proposalId][msg.sender]) revert SimpleDAO__AlreadyVoted();

        // VOTE
        if (support) {
            proposal.forVotes += voterWeight;
        } else if (support == false) {
            proposal.againstVotes += voterWeight;
        }

        // Mark caller voted as true
        s_hasVoted[proposalId][msg.sender] = true;

        emit VoteCast(proposalId, msg.sender, support, voterWeight);
    }

    /// @notice Queue a successful proposal into the timelock.
    /// @param proposalId ID of the proposal.
    /// @return eta Timestamp when the proposal can be executed.
    function queueProposal(uint256 proposalId) external returns (uint64 eta) {
        // Validate proposal
        if (proposalId > s_proposalCount || proposalId == 0) revert SimpleDAO__InvalidProposal();

        Proposal storage proposal = s_proposals[proposalId];

        // Verify voting not active
        if (block.timestamp <= proposal.endTime) revert SimpleDAO__VotingNotEnded();

        // Verify quorum reached
        if ((proposal.forVotes + proposal.againstVotes) < i_quorum) revert SimpleDAO__ProposalNotSuccessful();

        // Verify enough forVotes
        if (proposal.forVotes <= proposal.againstVotes) revert SimpleDAO__ProposalNotSuccessful();

        // Verify proposal not already queued
        if (proposal.queued) revert SimpleDAO__ProposalAlreadyQueued();

        // Verify proposal not yet executed
        if (proposal.executed) revert SimpleDAO__ProposalAlreadyExecuted();

        // 
        proposal.eta = uint64(i_timelock.queue(proposalId));

        proposal.queued = true;

        emit ProposalQueued(proposalId, proposal.eta);

        return proposal.eta;
    }

    /// @notice Mark a proposal as executed after timelock execution.
    ///         (Depending on design, this may be called by DAO or timelock.)
    /// @param proposalId ID of the proposal.
    function markExecuted(uint256 proposalId) external {
        // Validate proposal
        if (proposalId > s_proposalCount || proposalId == 0) revert SimpleDAO__InvalidProposal();

        if (msg.sender != address(i_timelock)) revert SimpleDAO__OnlyTimelock();

        Proposal storage proposal = s_proposals[proposalId];

        if (proposal.executed == true) revert SimpleDAO__ProposalAlreadyExecuted();

        proposal.executed = true;

        emit ProposalExecuted(proposalId);
    }


    // ███▓▓▒▒░░░░░────────────────===[  View Helpers  ]===────────────────░░░░░▒▒▓▓███

    function getProposal(uint256 proposalId) external view returns (Proposal memory) {
        return s_proposals[proposalId];

    }

    function hasVoted(uint256 proposalId, address voter) external view returns (bool) {
        return s_hasVoted[proposalId][voter];

    }

    function proposalCount() external view returns (uint256) {
        return s_proposalCount;

    }


}
