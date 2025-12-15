// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

// ░  ░░░░░░░░        ░░       ░░░       ░░░░      ░░░       ░░░        ░░        ░░░      ░░
// ▒  ▒▒▒▒▒▒▒▒▒▒▒  ▒▒▒▒▒  ▒▒▒▒  ▒▒  ▒▒▒▒  ▒▒  ▒▒▒▒  ▒▒  ▒▒▒▒  ▒▒▒▒▒  ▒▒▒▒▒  ▒▒▒▒▒▒▒▒  ▒▒▒▒▒▒▒
// ▓  ▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓       ▓▓▓       ▓▓▓  ▓▓▓▓  ▓▓       ▓▓▓▓▓▓  ▓▓▓▓▓      ▓▓▓▓▓      ▓▓
// █  ███████████  █████  ████  ██  ███  ███        ██  ███  ██████  █████  ██████████████  █
// █        ██        ██       ███  ████  ██  ████  ██  ████  ██        ██        ███      ██

library MathLib {
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function clamp(uint256 x, uint256 lo, uint256 hi) internal pure returns (uint256) {
        if (x > hi) return hi;
        if (x < lo) return lo;
        return x;
    }
}

library ArrLib {
    error ArrLib__InvalidIndex();

    function at(uint256[] storage arr, uint256 index) internal view returns (uint256) {
        if (index >= arr.length) revert ArrLib__InvalidIndex();
        return arr[index];
    }

    function pushUnique(uint256[] storage arr, uint256 value) internal returns (bool) {
        for (uint256 index = 0; index < arr.length; index++) {
            if (arr[index] == value) {
                return false;
            }
        }

        arr.push(value);
        return true;
    }

    function len(uint256[] storage arr) public view returns (uint256) {
        return arr.length;
    }
}

contract LibrariesDemo {
    using MathLib for uint256;
    using ArrLib for uint256[];

    uint256[] private array = [1, 2, 3, 4, 5];

    function findSmallerValue(uint256 a, uint256 b) public pure returns (uint256) {
        return a.min(b);
    }

    function clampScore(uint256 score, uint256 a, uint256 b) public pure returns (uint256) {
        return MathLib.clamp(score, a, b);
    }

    function valueAt(uint256 index) public view returns (uint256) {
        return array.at(index);
    }

    function pushUnique(uint256 value) public returns (bool) {
        return array.pushUnique(value);
    }

    function getLength() public view returns (uint256) {
        return array.length;
    }
}
