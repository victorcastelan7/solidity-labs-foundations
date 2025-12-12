// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {Test, console2} from "forge-std/Test.sol";
import {SimpleDAO} from "../../../../src/projects/SimpleDAO/SimpleDao.sol";
import {SimpleTimelock} from "./SimpleTimelock.t.sol";

contract TestSimpleDAO is Test {
    SimpleDAO simpleDAO;
    SimpleTimelock timeLock;
    address PROPOSER = makeAddr("proposer");
    address USER = makeAddr("user");
    uint256 quorum = 1;
    uint256 votingPeriod = 604800; // 1 week
    uint256 proposalId;
    string proposalDescription = "This is a test proposal";

    function setUp() public {
        timeLock = new SimpleTimelock(86400, address(0));
        simpleDAO = new SimpleDAO(address(timeLock), quorum, votingPeriod);

        timeLock.setDAO(address(simpleDAO));
    }
    

// ███▓▓▒▒░░░░░─────────────===[  TEST propose  ]===─────────────░░░░░▒▒▓▓███

    function testProposalIDStoresAndIncreases() public createProposal {
        assertEq(proposalId, 1, "First proposal initialized with Id of 1");

        // Create second proposal
        vm.prank(PROPOSER);
        uint256 proposalId2 = simpleDAO.propose(proposalDescription);
        assertEq(proposalId2, 2, "Second proposal initialized with Id of 2");
    }

    function testProposalStructPopulatedCorrectly() public createProposal {
        SimpleDAO.Proposal memory proposal = simpleDAO.getProposal(proposalId);

        assert(proposal.proposer == PROPOSER);
        assert(proposal.forVotes == 0);
        assert(proposal.againstVotes == 0);
        assert(proposal.endTime == (uint256(proposal.startTime) + votingPeriod));
        assert(proposal.eta == 0);
        assert(proposal.executed == false);
        assert(proposal.queued == false);
        assert(keccak256(bytes(proposal.description)) == keccak256(bytes(proposalDescription)));
    }

    function testProposalEmitsCorrectly() public {
        vm.prank(PROPOSER);
        vm.expectEmit(true, true, false, false);
        emit SimpleDAO.ProposalCreated(1, PROPOSER, 0, 0, "");
        simpleDAO.propose(proposalDescription);

    }


// ███▓▓▒▒░░░░░─────────────===[  TEST vote  ]===─────────────░░░░░▒▒▓▓███

    function testVoteRevertsIfProposalNotValid() public createProposal {
        vm.prank(USER);
        vm.expectRevert(SimpleDAO.SimpleDAO__InvalidProposal.selector);
        simpleDAO.vote(5, true);

        vm.prank(USER);
        vm.expectRevert(SimpleDAO.SimpleDAO__InvalidProposal.selector);
        simpleDAO.vote(0, true);
    }

    function testRevertsIfVotingWindowNotOpen() public createProposal {
        // Revert if voting window has passed
        vm.warp(simpleDAO.getProposal(proposalId).startTime + votingPeriod + 1);
        vm.roll(block.number);

        vm.prank(USER);
        vm.expectRevert(SimpleDAO.SimpleDAO__VotingNotActive.selector);
        simpleDAO.vote(proposalId, true);
    }

    function testRevertsIfCallerHasAlreadyVoted() public createProposal {
        // Cast initial vote
        vm.prank(USER);
        simpleDAO.vote(proposalId, true);

        // Cast second vote
        vm.prank(USER);
        vm.expectRevert(SimpleDAO.SimpleDAO__AlreadyVoted.selector);
        simpleDAO.vote(proposalId, true);
    }

    function testVotesAreCountedCorrectly() public createProposal {
        // Cast for vote
        vm.prank(USER);
        simpleDAO.vote(proposalId, true);

        assertEq(simpleDAO.getProposal(proposalId).forVotes, 1, "1 for vote counted");

        // Cast against vote
        address USER2 = makeAddr("user2");
        vm.prank(USER2);
        simpleDAO.vote(proposalId, false);

        assertEq(simpleDAO.getProposal(proposalId).againstVotes, 1, "1 against vote counted");
    }

    function testEmitsVoteCast() public createProposal {
        // Cast for vote
        vm.prank(USER);
        vm.expectEmit(true, true, false, false);
        emit SimpleDAO.VoteCast(proposalId, USER, true, 1);
        simpleDAO.vote(proposalId, true);
    }


// ███▓▓▒▒░░░░░─────────────===[  TEST queueProposal  ]===─────────────░░░░░▒▒▓▓███

    function testRevertQueueingIfInvalidProposal() public createProposal {
      vm.prank(USER);
      vm.expectRevert(SimpleDAO.SimpleDAO__InvalidProposal.selector);
      simpleDAO.queueProposal(5);

      vm.prank(USER);
      vm.expectRevert(SimpleDAO.SimpleDAO__InvalidProposal.selector);
      simpleDAO.queueProposal(0);
    }

    function testRevertQueuingIfVotingActive() public createProposal {
      vm.prank(USER);
      vm.expectRevert(SimpleDAO.SimpleDAO__VotingNotEnded.selector);
      simpleDAO.queueProposal(proposalId);
    }

    function testRevertIfQuorumNotReached() public createProposal {
      vm.warp(block.timestamp + simpleDAO.i_votingPeriod() + 1);
      vm.roll(block.number);

      vm.expectRevert(SimpleDAO.SimpleDAO__ProposalNotSuccessful.selector);
      simpleDAO.queueProposal(proposalId);
    }

    function testRevertIfNotEnoughForVotes() public createProposal {
      vm.prank(USER);
      simpleDAO.vote(proposalId, false);

      vm.warp(block.timestamp + simpleDAO.i_votingPeriod() + 1);
      vm.roll(block.number);

      vm.prank(USER);
      vm.expectRevert(SimpleDAO.SimpleDAO__ProposalNotSuccessful.selector);
      simpleDAO.queueProposal(proposalId);
    }

    function testRevertIfAlreadyQueued() public createProposal {
      vm.prank(USER);
      simpleDAO.vote(proposalId, true);

      vm.warp(block.timestamp + simpleDAO.i_votingPeriod() + 1);
      vm.roll(block.number);

      vm.prank(USER);
      simpleDAO.queueProposal(proposalId);

      vm.prank(USER);
      vm.expectRevert(SimpleDAO.SimpleDAO__ProposalAlreadyQueued.selector);
      simpleDAO.queueProposal(proposalId);
    }

    function testEmitsProposalQueued() public createProposal {
      vm.prank(USER);
      simpleDAO.vote(proposalId, true);

      vm.warp(block.timestamp + simpleDAO.i_votingPeriod() + 1);
      vm.roll(block.number);

      vm.prank(USER);
      vm.expectEmit(true, false, false, false);
      emit SimpleDAO.ProposalQueued(proposalId, simpleDAO.getProposal(proposalId).eta);
      simpleDAO.queueProposal(proposalId);

      // Proposal queued marked as true
      assertEq(simpleDAO.getProposal(proposalId).queued, true);
    }


// ███▓▓▒▒░░░░░─────────────===[  TEST markExecuted  ]===─────────────░░░░░▒▒▓▓███

    function testRevertIfInvalidProposal() public createProposal {
        vm.prank(address(timeLock));
        vm.expectRevert(SimpleDAO.SimpleDAO__InvalidProposal.selector);
        simpleDAO.markExecuted(2);
        
    }

    function testRevertIfCallerIsNotTimelock() public createProposal {
        vm.prank(USER);
        vm.expectRevert(SimpleDAO.SimpleDAO__OnlyTimelock.selector);
        simpleDAO.markExecuted(proposalId);

    }

    function testRevertIfMarkExecutedCalledTwice() public createProposal {
        vm.prank(address(timeLock));
        simpleDAO.markExecuted(proposalId);

        vm.prank(address(timeLock));
        vm.expectRevert(SimpleDAO.SimpleDAO__ProposalAlreadyExecuted.selector);
        simpleDAO.markExecuted(proposalId);

    }

    function testMarkExecutedHappyPath() public createProposal {
        
        vm.prank(USER);
        simpleDAO.vote(proposalId, true);

        vm.warp(block.timestamp + simpleDAO.i_votingPeriod() + 1);
        vm.roll(block.number);

        vm.prank(USER);
        simpleDAO.queueProposal(proposalId);

        uint256 eta = simpleDAO.getProposal(proposalId).eta;

        vm.warp(eta + 1);

        vm.prank(address(timeLock));
        vm.expectEmit(true, false, false, false);
        emit SimpleDAO.ProposalExecuted(proposalId);

        simpleDAO.markExecuted(proposalId);

        assertEq(simpleDAO.getProposal(proposalId).executed, true);

    }


// markExecuted reverts if called twice.
// Happy path: event + executed == true.

// ███▓▓▒▒░░░░░─────────────===[  MODIFIERS  ]===─────────────░░░░░▒▒▓▓███

    modifier createProposal() {
        vm.prank(PROPOSER);
        proposalId = simpleDAO.propose(proposalDescription);
        _;
    }
}
