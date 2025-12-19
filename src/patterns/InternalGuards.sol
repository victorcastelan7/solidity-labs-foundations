// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

contract InternalGuards {
    error InternalGuards__NotOwner();
    error InternalGuards__Paused();

    address private immutable i_owner;
    bool private s_paused;

    constructor() {
        i_owner = msg.sender;
    }

    // Guards
    function onlyOwner() internal view {
        if (msg.sender != i_owner) revert InternalGuards__NotOwner();
    }

    function whenNotPaused() internal view {
        if (s_paused) revert InternalGuards__Paused();
    }

    // Admin
    function pauseState(bool state) external {
        onlyOwner();
        s_paused = state;
    }

    // Add function
    function addTen(uint256 x) external view returns (uint256) {
        whenNotPaused();
        return x + 10;
    }

    // Getters

    function getOwner() external view returns (address) {
        return i_owner;
    }

    function getPauseState() external view returns (bool) {
        return s_paused;
    }
}

