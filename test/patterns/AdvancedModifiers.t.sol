// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import { Test, console2 } from "forge-std/Test.sol";
import { AdvancedModifier } from "../../src/patterns/AdvancedModifiers.sol";

contract TestAdvancedModifier is Test {
  AdvancedModifier advMod;
  address USER = makeAddr("user");
  address owner;

  function setUp() public {
    advMod = new AdvancedModifier();
    owner = advMod.getOwner();
  }

  function testRevertIfNotOwner() public {
    vm.startPrank(USER);
    vm.expectRevert(AdvancedModifier.AdvancedModifier__OnlyOwner.selector);
    advMod.changeState(AdvancedModifier.AccessState.Paused);

    vm.expectRevert(AdvancedModifier.AdvancedModifier__OnlyOwner.selector);
    advMod.setPermission(USER, true);

    vm.expectRevert(AdvancedModifier.AdvancedModifier__OnlyOwner.selector);
    advMod.setLimit(1000);
    vm.stopPrank();
  }

  function testNotAllowedCannotDoThing() public {
    vm.prank(owner);
    advMod.setPermission(USER, false);

    assertEq(advMod.getUserPermissions(USER), false);

    vm.prank(USER);
    vm.expectRevert(AdvancedModifier.AdvancedModifier__InsufficientPermissions.selector);
    advMod.doThing(7);
  }

  function testPausePreventsDoThing() public {
    vm.startPrank(owner);
    advMod.changeState(AdvancedModifier.AccessState.Paused);
    advMod.setPermission(USER, true);
    vm.stopPrank();

    vm.prank(USER);
    vm.expectRevert(AdvancedModifier.AdvancedModifier__PausedState.selector);
    advMod.doThing(7);
  }

  function testRevertAfterLimitReached() public {

    AdvancedModifier.AccessState initialAccessState = advMod.getAccessState();
    assertEq(uint256(initialAccessState), uint256(AdvancedModifier.AccessState.Active));

    uint256 initialSecretValue = advMod.getSecretValue();
    assertEq(initialSecretValue, 0);

    bool initialUserPermission = advMod.getUserPermissions(USER);
    assertEq(initialUserPermission, false);

    vm.prank(owner);
    advMod.setPermission(USER, true);
    bool afterUserPermission = advMod.getUserPermissions(USER);
    assertEq(afterUserPermission, true);

    // Do thing first time
    vm.prank(USER);
    advMod.doThing(7);

    assertEq(advMod.getSecretValue(), 7); // 7 + 0 = 7

    uint256 afterSecretValue = advMod.getSecretValue(); // New value = 7

    // Do thing again
    vm.prank(USER);
    advMod.doThing(7);

    assertEq(advMod.getSecretValue(), 14); // 7 + 7 = 14

    afterSecretValue = advMod.getSecretValue(); // New value = 14

    // Do thing again
    vm.prank(USER);
    advMod.doThing(100);

    assertEq(advMod.getSecretValue(), 114); // 14 + 100 = 114

    // Verify paused state
    AdvancedModifier.AccessState afterAccessState = advMod.getAccessState();
    assertEq(uint256(afterAccessState), 1);

    // Do thing final attempt
    vm.prank(USER);
    vm.expectRevert(AdvancedModifier.AdvancedModifier__PausedState.selector);
    advMod.doThing(1);
  }
}



