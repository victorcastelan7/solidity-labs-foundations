// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

contract Errors {
  error Errors__InsufficientBalance(uint256 withdrawAmount, uint256 balance);
  error Errors__NotOwner();
  error Errors__ZeroDeposit();
  error Errors__TransactionFailed();

  address private immutable i_owner;
  mapping(address => uint256) private s_balances;

  constructor() {
    i_owner = msg.sender;
  }

  function deposit() external payable {
    if (msg.value == 0) {
      revert Errors__ZeroDeposit();
    }

    s_balances[msg.sender] += msg.value;
  }

  function withdraw(uint256 withdrawAmount) external {
    uint256 balance = s_balances[msg.sender];

    if (withdrawAmount > balance) {
      revert Errors__InsufficientBalance(withdrawAmount, balance);
    }

    s_balances[msg.sender] -= withdrawAmount;

    (bool success, ) = address(msg.sender).call{value: withdrawAmount}("");
    if (!success) {
      revert Errors__TransactionFailed();
    }
  }

  function sweep(address to) external {
    if (msg.sender != i_owner) {
      revert Errors__NotOwner();
    }

    uint256 balance = address(this).balance;

    (bool success, ) = to.call{value: balance}("");
    if (!success) {
      revert Errors__TransactionFailed();
    }
  }

  function getBalance(address user) public view returns (uint256) {
    return (s_balances[user]);
  }

  function getOwner() public view returns (address) {
    return i_owner;
  }
}