// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;
import { Test } from "forge-std/Test.sol";
import { SimpleTimelock } from "../../../../src/projects/SimpleDAO/SimpleTimelock.sol";
import { SimpleDAO } from "../../../../src/projects/SimpleDAO/SimpleDao.sol";

contract TestSimpleTimeLock is Test {

  SimpleTimelock timeLock;
  SimpleDAO simpleDAO;
  address PROPOSER = makeAddr("proposer");
  address USER = makeAddr("user");
  uint256 proposalId = 1;
  string proposalDescription = "This is a test proposal";

  function setUp() public {
    timeLock = new SimpleTimelock(86400, address(0));
    simpleDAO = new SimpleDAO(address(timeLock), 1, 86400);
    vm.prank(PROPOSER);
    simpleDAO.propose(proposalDescription);

    timeLock.setDAO(address(simpleDAO));

    vm.prank(USER);
    simpleDAO.vote(proposalId, true);

    vm.warp(block.timestamp + simpleDAO.i_votingPeriod() + 1);
    vm.roll(block.number);
  }

  function testQueueRevertsIfNotDAO() public {

    vm.prank(USER);
    vm.expectRevert(SimpleTimelock.SimpleTimelock__OnlyDAO.selector);
    timeLock.queue(proposalId);
  }

  function testQueueStoresEtaAndReturnsIt() public {

    vm.prank(address(simpleDAO));
    uint256 eta = timeLock.queue(proposalId);

    assertEq(eta, timeLock.getEta(proposalId), "eta return should match stored eta");

    uint256 expected = block.timestamp + 86400;
    assertEq(eta, expected, "eta should be now + minDelay");

  }

  function testExecuteRevertsIfNotQueued() public {

    vm.prank(USER);
    vm.expectRevert(SimpleTimelock.SimpleTimelock__NotQueued.selector);
    timeLock.execute(proposalId);
  }

  function testExecuteRevertsIfEtaNotReached() public {

    vm.prank(address(simpleDAO));
    timeLock.queue(proposalId);

    vm.prank(USER);
    vm.expectRevert(SimpleTimelock.SimpleTimelock__TimestampNotReached.selector);

    timeLock.execute(proposalId);
  }

  function testExecuteCallsBackDAOAndClearsEta() public {

    vm.prank(USER);
    simpleDAO.queueProposal(proposalId);

    uint256 eta = simpleDAO.getProposal(proposalId).eta;

    vm.warp(eta + 1);

    vm.prank(USER);
    timeLock.execute(proposalId);

    assertEq(simpleDAO.getProposal(proposalId).executed, true);
    assertEq(timeLock.getEta(proposalId), 0);

  }



}





