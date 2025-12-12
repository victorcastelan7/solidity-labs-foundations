// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;                                                   

import {Errors} from "../../src/patterns/Errors.sol";
import {Test, console2} from "forge-std/Test.sol";

contract TestErrors is Test {
    Errors errors;
    uint256 depositAmount = 0.1 ether;
    uint256 fundAmount = 100 ether;
    address USER = makeAddr("user");

    function setUp() public {
        errors = new Errors();

        vm.deal(USER, fundAmount);
    }

    function testRevertsOnZeroDeposit() public {
        vm.prank(USER);
        vm.expectRevert(Errors.Errors__ZeroDeposit.selector);
        errors.deposit{value: 0}();
    }

    function testDepositUpdatesMapping() public {
        vm.prank(USER);
        errors.deposit{value: depositAmount}();

        assert(depositAmount == errors.getBalance(USER));
    }

    function testWithdrawRevertsIfInsufficientBalance() public {
        uint256 withdrawAmount = 1 ether;
        uint256 balance;

        vm.prank(USER);
        errors.deposit{value: depositAmount}();
        balance = errors.getBalance(USER);

        vm.prank(USER);
        vm.expectRevert(abi.encodeWithSelector(Errors.Errors__InsufficientBalance.selector, withdrawAmount, balance));
        errors.withdraw(withdrawAmount);
    }

    function testWithdrawUpdatesMapping() public {
        uint256 withdrawAmount = 0.02 ether;
        uint256 endingBalance;

        vm.startPrank(USER);
        errors.deposit{value: depositAmount}(); // 0.1 ether deposit
        errors.withdraw(withdrawAmount);
        vm.stopPrank();

        endingBalance = errors.getBalance(USER);

        assert(endingBalance == (depositAmount - withdrawAmount));
    }

    function testRevertsSweepIfNotOwner() public {
        address RECIPIENT = makeAddr("recipient");

        vm.prank(USER);
        vm.expectRevert(Errors.Errors__NotOwner.selector);
        errors.sweep(RECIPIENT);
    }

    function testSweepTransfersFunds() public {
        address owner = errors.getOwner();
        address RECIPIENT = makeAddr("recipient");
        uint256 amountOfUsers = 11;

        for (uint256 i = 1; i < amountOfUsers; i++) {
            address newUser = address(uint160(i));
            hoax(newUser, fundAmount);
            errors.deposit{value: depositAmount}(); // 0.1 ether
        }

        uint256 contractBalanceAfterDeposit = address(errors).balance;

        assertEq(
            contractBalanceAfterDeposit,
            (amountOfUsers - 1) * depositAmount,
            "Contract balance should have received all deposits"
        );

        vm.prank(owner);
        errors.sweep(RECIPIENT);

        uint256 contractBalanceAfterSweep = address(errors).balance;
        uint256 recipientBalanceAfterSweep = address(RECIPIENT).balance;

        assertEq(contractBalanceAfterSweep, 0, "Contract balance should be empty after sweep");

        assertEq(
            contractBalanceAfterDeposit, recipientBalanceAfterSweep, "Recipient should receive full contract balance"
        );
    }
}
