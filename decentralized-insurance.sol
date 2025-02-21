// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract DecentralizedInsurance {
    address public admin;
    uint256 public totalPool;
    mapping(address => uint256) public contributions;
    mapping(address => uint256) public pendingClaims;
    
    event Contribution(address indexed user, uint256 amount);
    event ClaimRequested(address indexed user, uint256 amount);
    event ClaimApproved(address indexed user, uint256 amount);
    event ClaimRejected(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    constructor() {
        admin = msg.sender;
    }
    
    function contribute() external payable {
        require(msg.value > 0, "Contribution must be greater than zero");
        contributions[msg.sender] += msg.value;
        totalPool += msg.value;
        emit Contribution(msg.sender, msg.value);
    }
    
    function requestClaim(uint256 amount) external {
        require(amount > 0, "Invalid claim amount");
        require(contributions[msg.sender] > 0, "Must be a contributor");
        require(amount <= totalPool / 2, "Claim exceeds allowed limit");
        pendingClaims[msg.sender] = amount;
        emit ClaimRequested(msg.sender, amount);
    }
    
    function approveClaim(address user) external onlyAdmin {
        uint256 claimAmount = pendingClaims[user];
        require(claimAmount > 0, "No pending claim");
        require(claimAmount <= totalPool, "Insufficient funds in pool");
        
        pendingClaims[user] = 0;
        totalPool -= claimAmount;
        payable(user).transfer(claimAmount);
        emit ClaimApproved(user, claimAmount);
    }
    
    function rejectClaim(address user) external onlyAdmin {
        require(pendingClaims[user] > 0, "No pending claim");
        uint256 claimAmount = pendingClaims[user];
        pendingClaims[user] = 0;
        emit ClaimRejected(user, claimAmount);
    }
    
    function withdrawContribution(uint256 amount) external {
        require(amount > 0, "Invalid withdrawal amount");
        require(contributions[msg.sender] >= amount, "Insufficient contribution");
        require(totalPool >= amount, "Insufficient pool funds");
        
        contributions[msg.sender] -= amount;
        totalPool -= amount;
        payable(msg.sender).transfer(amount);
        emit Withdrawal(msg.sender, amount);
    }
}
