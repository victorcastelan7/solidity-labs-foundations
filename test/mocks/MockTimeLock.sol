// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import { ISimpleTimelock } from "../../../../src/projects/SimpleDAO/SimpleDao.sol";

contract MockTimelock is ISimpleTimelock {
    uint256 public lastQueuedProposal;
    uint256 public etaToReturn;

    constructor(uint256 _etaToReturn) {
        etaToReturn = _etaToReturn;
    }

    function queue(uint256 proposalId) external returns (uint256 eta) {
        lastQueuedProposal = proposalId;
        return etaToReturn; 
    }

    function execute(uint256) external {
        // no-op
    }
}
