// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import { Test } from "forge-std/Test.sol";
import { Modifiers } from "../../src/patterns/Modifiers.sol";

contract TestModifiers is Test {
  uint256 startingValue = 100;
  uint256 amount = 1;
  address owner;
  address USER = makeAddr("user");
  Modifiers modifiers;

  function setUp() public {
     modifiers = new Modifiers(startingValue);
     owner = modifiers.getOwner();
  }

  function testStartingValueIncrements() public {
    modifiers.increment(amount);

    uint256 valueAfterIncrement = modifiers.getValue();

    assertEq(startingValue + amount, valueAfterIncrement, "startingValue (100) incremented by amount (1), totaling 101");
  }

  function testRevertIfIncrementZero() public {
    vm.expectRevert(Modifiers.Modifiers__InvalidAmount.selector);
    modifiers.increment(0);
  }

  function testStartingValueDecrements() public {
    vm.prank(owner);
    modifiers.decrement(amount);

    uint256 valueAfterDecrement = modifiers.getValue();

    assertEq(startingValue - amount, valueAfterDecrement, "startingValue (100) decremented by amount (1), totaling 99");
  }

  function testRevertIfDecrementZero() public {
    vm.prank(owner);
    vm.expectRevert(Modifiers.Modifiers__InvalidAmount.selector);
    modifiers.decrement(0);
  }

  function testRevertIfNotOwner() public {
    vm.prank(USER);
    vm.expectRevert(Modifiers.Modifiers__NotOwner.selector);
    modifiers.decrement(amount);
  }

  function testValueResets() public {
    modifiers.increment(amount);
    vm.prank(owner);
    modifiers.reset();

    uint256 valueAfterReset = modifiers.getValue();

    assertEq(valueAfterReset, 0, "Value is reset to 0");
  }
  
  function testNewValueUpdatesOldValue() public {
    uint256 newValue = 50;
    vm.prank(owner);
    modifiers.setValue(newValue);
    uint256 valueAfterSetNewValue = modifiers.getValue();

    assertEq(newValue, valueAfterSetNewValue, "Value set to 50");
  }
}