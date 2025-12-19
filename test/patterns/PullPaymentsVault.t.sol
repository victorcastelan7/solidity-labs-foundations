// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {PullPaymentsVault} from "../../src/patterns/PullPaymentsVault.sol";

contract testPullPaymentsVault is Test {
    PullPaymentsVault pv;
    address USER = makeAddr("user");

    function setUp() public {
        pv = new PullPaymentsVault();
        vm.deal(USER, 100 ether);
    }

    function testDepositsToCorrectAddress() public {
        uint256 depositAmount = 1 ether;
        vm.prank(USER);
        pv.deposit{value: depositAmount}(USER);

        assertEq(pv.balanceOf(USER), depositAmount);
        assertEq(address(pv).balance, depositAmount);
    }

    function testWithdrawWithZeroBalanceReverts() public {
        vm.prank(USER);
        vm.expectRevert(PullPaymentsVault.PullPaymentsVault__ZeroBalance.selector);
        pv.withdraw();
    }

    function testWithdrawTransfersEthAndSetsBalanceToZero() public {
        uint256 depositAmount = 1 ether;
        vm.prank(USER);
        pv.deposit{value: depositAmount}(USER);

        uint256 beforeWithdrawBalance = USER.balance;

        vm.prank(USER);
        pv.withdraw();

        uint256 afterWithdrawBalance = USER.balance;

        assertEq(afterWithdrawBalance, beforeWithdrawBalance + depositAmount);
        assertEq(pv.balanceOf(USER), 0);
        assertEq(address(pv).balance, 0);
    }

    function testReentrancyCannotDrainMoreThanCredit() public {
        Reenterer attacker = new Reenterer(pv);

        // credit attacker with 1 ether from USER
        vm.prank(USER);
        pv.deposit{value: 1 ether}(address(attacker));

        uint256 vaultBefore = address(pv).balance;
        uint256 attackerBefore = address(attacker).balance;

        attacker.attack();

        // attacker should only receive 1 ether once
        assertEq(address(attacker).balance, attackerBefore + 1 ether);
        assertEq(address(pv).balance, vaultBefore - 1 ether);
        assertEq(pv.balanceOf(address(attacker)), 0);
    }
}

contract Reenterer {
    PullPaymentsVault private immutable pv;
    bool public tried;

    constructor(PullPaymentsVault _pv) {
        pv = _pv;
    }

    function attack() external {
        pv.withdraw();
    }

    receive() external payable {
        if (!tried) {
            tried = true;
            // attempt reentrancy
            try pv.withdraw() {} catch {}
        }
    }
}
