// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { SimpleDAO } from "./SimpleDAO.sol";


/// @title SimpleTimelock
/// @notice Minimal timelock with queue + timestamp check + execute (no real call logic yet).
contract SimpleTimelock {


    // ███▓▓▒▒░░░░░────────────────===[  Storage  ]===────────────────░░░░░▒▒▓▓███

    uint256 public immutable i_minDelay;
    address public i_dao;
    // proposalId => eta (execution time)
    mapping(uint256 => uint256) private s_eta;


    // ███▓▓▒▒░░░░░────────────────===[  Events  ]===────────────────░░░░░▒▒▓▓███

    event OperationQueued(uint256 indexed proposalId, uint256 eta);
    event OperationExecuted(uint256 indexed proposalId);


    // ███▓▓▒▒░░░░░────────────────===[  Errors  ]===────────────────░░░░░▒▒▓▓███

    error SimpleTimelock__OnlyDAO();
    error SimpleTimelock__NotQueued();
    error SimpleTimelock__TimestampNotReached();


    // ███▓▓▒▒░░░░░────────────────===[  Constructor  ]===────────────────░░░░░▒▒▓▓███

    constructor(uint256 minDelay, address dao) {
        i_minDelay = minDelay;
        i_dao = dao;
    }


    // ███▓▓▒▒░░░░░────────────────===[  Modifiers ]===────────────────░░░░░▒▒▓▓███

    modifier onlyDAO() {
        if (msg.sender != i_dao) {
            revert SimpleTimelock__OnlyDAO();
        }
        _;
    }


    // ███▓▓▒▒░░░░░────────────────===[  External API (signatures only)  ]===────────────────░░░░░▒▒▓▓███

    /// @notice Queue an operation associated with a proposal.
    /// @dev Only the DAO can queue operations.
    /// @param proposalId ID of the proposal in the DAO.
    /// @return eta Timestamp when the operation becomes executable.
    function queue(uint256 proposalId) external onlyDAO returns (uint256 eta) {

        eta = block.timestamp + i_minDelay;
        s_eta[proposalId] = eta;

        emit OperationQueued(proposalId, eta);

        return eta;
    }

    /// @notice Execute a previously queued operation.
    /// @param proposalId ID of the proposal in the DAO.
    function execute(uint256 proposalId) external {

        // Verify proposal is queued
        if (s_eta[proposalId] == 0) revert SimpleTimelock__NotQueued();

        // Verify delay has passed
        if (block.timestamp < s_eta[proposalId]) revert SimpleTimelock__TimestampNotReached();

        // Mark as used
        s_eta[proposalId] = 0;

        // Mark executed in main contract
        SimpleDAO(i_dao).markExecuted(proposalId);
    }

    function setDAO(address newDAO) external {
        i_dao = newDAO;
    }

    // ███▓▓▒▒░░░░░────────────────===[  View Helpers  ]===────────────────░░░░░▒▒▓▓███

    function getEta(uint256 proposalId) external view returns (uint256) {
        return s_eta[proposalId];
    }

    function isExecuted(uint256 proposalId) external view returns (bool) {
        return SimpleDAO(i_dao).getProposal(proposalId).executed;
    }
}
