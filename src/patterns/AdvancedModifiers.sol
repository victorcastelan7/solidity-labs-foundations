// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

contract AdvancedModifier {
    uint256 private limit = 100;
    uint256 private secretValue;
    address private immutable i_owner;
    mapping(address => bool) private s_allowed;
    enum AccessState {
        Active,
        Paused
    }
    AccessState accessState;

    //event ThingDone()

    error AdvancedModifier__OnlyOwner();
    error AdvancedModifier__PausedState();
    error AdvancedModifier__InsufficientPermissions();
    
    constructor() {
        i_owner = msg.sender;
        accessState = AccessState.Active;
    }

    //modifiers
    modifier onlyOwner() {
        if (msg.sender != i_owner) revert AdvancedModifier__OnlyOwner();
        _;
    }

    modifier isActive() {
        if (accessState != AccessState.Active) revert AdvancedModifier__PausedState();
        _;
    }

    modifier onlyAllowed(address sender) {
        if (!s_allowed[sender]) revert AdvancedModifier__InsufficientPermissions();
        _;
    }

    modifier autoPause(uint256 value) {
        if (value > limit || secretValue > limit - value) accessState = AccessState.Paused;
        _;
    }

    //admin

    function setPermission(address user, bool permission) external onlyOwner {
        s_allowed[user] = permission;
    }

    function setLimit(uint256 newLimit) external onlyOwner {
        limit = newLimit;
    }

    function changeState(AccessState newState) external onlyOwner {
        accessState = newState;
    }

    //do thing
    function doThing(uint256 value) external isActive onlyAllowed(msg.sender) autoPause(value) returns (uint256) {
        secretValue += value;

        return value;
    }

    // GETTERS

    function getOwner() public view returns(address) {
        return i_owner;
    }
    
    function getUserPermissions(address user) public view returns (bool) {
        return s_allowed[user];
    }

    function getSecretValue() public view returns (uint256) {
        return secretValue;
    }

    function getAccessState() public view returns (AccessState) {
        return accessState;
    }
    
}
