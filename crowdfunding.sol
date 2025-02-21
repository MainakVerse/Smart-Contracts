// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SmartCrowdfunding {
    address public owner;
    uint256 public fundingGoal;
    uint256 public deadline;
    uint256 public totalFunds;
    bool public goalReached;
    bool public fundsWithdrawn;

    mapping(address => uint256) public contributions;

    event ContributionReceived(address indexed contributor, uint256 amount);
    event GoalReached(uint256 totalFunds);
    event FundsWithdrawnByOwner(uint256 amount);
    event RefundIssued(address indexed contributor, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this");
        _;
    }

    modifier crowdfundingActive() {
        require(block.timestamp < deadline, "Crowdfunding has ended");
        _;
    }

    modifier crowdfundingEnded() {
        require(block.timestamp >= deadline, "Crowdfunding is still active");
        _;
    }

    constructor(uint256 _fundingGoal, uint256 _durationInDays) {
        require(_fundingGoal > 0, "Funding goal must be greater than zero");
        require(_durationInDays > 0, "Duration must be greater than zero");

        owner = msg.sender;
        fundingGoal = _fundingGoal;
        deadline = block.timestamp + (_durationInDays * 1 days);
    }

    function contribute() external payable crowdfundingActive {
        require(msg.value > 0, "Contribution must be greater than zero");

        contributions[msg.sender] += msg.value;
        totalFunds += msg.value;

        emit ContributionReceived(msg.sender, msg.value);

        if (totalFunds >= fundingGoal) {
            goalReached = true;
            emit GoalReached(totalFunds);
        }
    }

    function withdrawFunds() external onlyOwner crowdfundingEnded {
        require(goalReached, "Funding goal not reached");
        require(!fundsWithdrawn, "Funds already withdrawn");

        fundsWithdrawn = true;
        uint256 amount = totalFunds;
        totalFunds = 0;

        (bool success, ) = owner.call{value: amount}("");
        require(success, "Transfer failed");

        emit FundsWithdrawnByOwner(amount);
    }

    function claimRefund() external crowdfundingEnded {
        require(!goalReached, "Funding goal was met, no refunds");
        require(contributions[msg.sender] > 0, "No contributions to refund");

        uint256 amount = contributions[msg.sender];
        contributions[msg.sender] = 0;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Refund failed");

        emit RefundIssued(msg.sender, amount);
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    receive() external payable {
        contribute();
    }
}

