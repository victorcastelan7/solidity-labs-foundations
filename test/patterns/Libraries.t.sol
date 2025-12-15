// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {LibrariesDemo, ArrLib} from "../../src/patterns/Libraries.sol";

contract TestLibraries is Test {
    LibrariesDemo lib;

    function setUp() public {
        lib = new LibrariesDemo();
    }

    function testSmallerValueReturned() public {
        uint256 value = lib.findSmallerValue(5, 9);
        assertEq(value, 5, "Function returns smaller value, 5");

        // Reverse
        value = lib.findSmallerValue(9, 5);
        assertEq(value, 5, "Function returns smaller value, 5");

        // Equal
        assertEq(lib.findSmallerValue(7, 7), 7);
    }

    function testClampReturns() public {
        // Test returns low
        uint256 clampResult = lib.clampScore(1, 3, 9);
        assertEq(clampResult, 3, "Low is returned");

        // Test returns high
        clampResult = lib.clampScore(11, 3, 9);
        assertEq(clampResult, 9, "High is returned");

        // Test returns score
        clampResult = lib.clampScore(3, 3, 3);
        assertEq(clampResult, 3, "Score is returned");

        assertEq(lib.clampScore(5, 3, 9), 5);
        assertEq(lib.clampScore(3, 3, 9), 3);
        assertEq(lib.clampScore(9, 3, 9), 9);
    }

    function testAtErrorIfInvalidIndex() public {
        assertEq(lib.valueAt(4), 5);

        vm.expectRevert(ArrLib.ArrLib__InvalidIndex.selector);
        lib.valueAt(5);
    }

    function testCorrectValueReturned() public {
        uint256 indexValue = lib.valueAt(0);
        assertEq(indexValue, 1, "Value returned is 1");
    }

    function testValueNotUniqueNotPushed() public {
        uint256 before = lib.getLength();
        assertFalse(lib.pushUnique(1));
        assertEq(lib.getLength(), before);
    }

    function testUniqueValuePushed() public {
        uint256 initialArrayLength = lib.getLength();
        assertEq(initialArrayLength, 5);

        bool pushResult = lib.pushUnique(6);
        assertEq(pushResult, true);
        assertEq(lib.valueAt(5), 6);

        uint256 arrayLengthAfterPush = lib.getLength();
        assertEq(arrayLengthAfterPush, initialArrayLength + 1);
    }
}
