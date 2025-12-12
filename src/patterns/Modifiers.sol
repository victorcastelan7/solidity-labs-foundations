// SPDX-License-Identifier: MIT
// Inspired by Solidity By Example: https://solidity-by-example.org/function-modifier/

pragma solidity ^0.8.30;

contract Modifiers {
    error Modifiers__NotOwner();
    error Modifiers__InvalidAmount();
    error Modifiers__Reentrancy();

    address private immutable i_owner;
    uint256 private s_value;
    bool private s_locked;

    constructor(uint256 initialValue) {
        i_owner = msg.sender;
        s_value = initialValue;
    }

    ///// MODIFIERS /////

    modifier onlyOwner() {
        if (msg.sender != i_owner) revert Modifiers__NotOwner();
        _;
    }

    modifier noReentrancy() {
        if (s_locked) revert Modifiers__Reentrancy();
        s_locked = true;
        _;
        s_locked = false;
    }

    modifier nonZero(uint256 amount) {
        if (amount == 0) revert Modifiers__InvalidAmount();
        _;
    }

    ///// FUNCTIONS /////

    function setValue(uint256 newValue) external onlyOwner nonZero(newValue) {
        s_value = newValue;
    }

    function increment(uint256 amount) external nonZero(amount) {
        s_value += amount;
    }

    function decrement(uint256 amount) external onlyOwner nonZero(amount) noReentrancy {
        s_value -= amount;
    }

    function reset() external onlyOwner {
        s_value = 0;
    }

    ///// GETTERS /////

    function getValue() external view returns (uint256) {
        return s_value;
    }

    function getOwner() external view returns (address) {
        return i_owner;
    }

    function isLocked() external view returns (bool) {
        return s_locked;
    }
}

// contract ModifiersExample {
//     // ----- Errors -----
//     error Modifiers__NotOwner();
//     error Modifiers__InvalidAmount();
//     error Modifiers__Reentrancy();

//     // ----- State -----
//     address private immutable i_owner;
//     bool private s_locked;
//     uint256 private s_value;

//     // ----- Constructor -----
//     constructor(uint256 initialValue) {
//         i_owner = msg.sender;
//         s_value = initialValue;
//     }

//     // ----- Modifiers -----

//     // Only the deployer / owner can call
//     modifier onlyOwner() {
//         if (msg.sender != i_owner) revert Modifiers__NotOwner();
//         _;
//     }

//     // Make sure an amount is > 0
//     modifier nonZero(uint256 amount) {
//         if (amount == 0) revert Modifiers__InvalidAmount();
//         _;
//     }

//     // Basic reentrancy guard
//     modifier noReentrancy() {
//         if (s_locked) revert Modifiers__Reentrancy();
//         s_locked = true;
//         _;
//         s_locked = false;
//     }

//     // ----- Functions -----

//     // Only owner, non-zero, sets the stored value
//     function setValue(uint256 newValue)
//         external
//         onlyOwner
//         nonZero(newValue)
//     {
//         s_value = newValue;
//     }

//     // Only owner, non-zero, protected by noReentrancy
//     function decrement(uint256 amount)
//         external
//         onlyOwner
//         nonZero(amount)
//         noReentrancy
//     {
//         s_value -= amount;
//     }

//     function getValue() external view returns (uint256) {
//         return s_value;
//     }

//     function getOwner() external view returns (address) {
//         return i_owner;
//     }

//     function isLocked() external view returns (bool) {
//         return s_locked;
//     }
// }
