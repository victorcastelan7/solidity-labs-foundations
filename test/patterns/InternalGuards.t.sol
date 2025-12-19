// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {InternalGuards} from "../../src/patterns/InternalGuards.sol";

contract TestInternalGuards is Test {
    InternalGuards ig;
    address owner;
    address USER = makeAddr("user");

    function setUp() public {
        ig = new InternalGuards();
        owner = ig.getOwner();
    }

    function testNonOwnerCannotPause() public {
        vm.prank(USER);
        vm.expectRevert(InternalGuards.InternalGuards__NotOwner.selector);
        ig.pauseState(true);
    }

    function testPausedPreventsAddTen() public {
        vm.prank(owner);
        ig.pauseState(true);

        vm.prank(USER);
        vm.expectRevert(InternalGuards.InternalGuards__Paused.selector);
        ig.addTen(5);
    }

    function testAddTenHappyPath() public {
        uint256 value = 5;
        vm.prank(USER);
        uint256 addTenResult = ig.addTen(value);

        assertEq(addTenResult, 10 + value);
    }
}

