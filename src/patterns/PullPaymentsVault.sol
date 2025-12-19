// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

contract PullPaymentsVault {
    mapping(address => uint256) private s_balance;

    error PullPaymentsVault__ZeroBalance();
    error PullPaymentsVault__TransactionFailed();
    error PullPaymentsVault__ZeroDeposit();
    error PullPaymentsVault__InvalidAddress();

    event Withdraw(address indexed user, uint256 amount);
    event Deposit(address indexed user, uint256 amount);

    function balanceOf(address user) external view returns (uint256) {
        return s_balance[user];
    }

    function depositFunds(address user) internal {
        if (msg.value == 0) revert PullPaymentsVault__ZeroDeposit();
        if (user == address(0)) revert PullPaymentsVault__InvalidAddress();

        s_balance[user] += msg.value;

        emit Deposit(user, msg.value);
    }

    function deposit(address user) external payable {
        depositFunds(user);
    }

    function withdrawFunds(address user) internal {
        if (s_balance[user] == 0) revert PullPaymentsVault__ZeroBalance();

        uint256 balance = s_balance[user];
        s_balance[user] = 0;

        emit Withdraw(user, balance);

        (bool success,) = user.call{value: balance}("");
        if (!success) revert PullPaymentsVault__TransactionFailed();
    }

    function withdraw() external {
        withdrawFunds(msg.sender);
    }
}

