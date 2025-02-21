// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DividendDistributor is ReentrancyGuard, Ownable {
    mapping(address => uint256) public investorShares;
    mapping(address => uint256) public withdrawnDividends;
    address[] public investors;
    uint256 public totalShares;
    uint256 public totalDividends;
    
    event Deposited(uint256 amount);
    event DividendsDistributed(uint256 amount);
    event Withdrawn(address investor, uint256 amount);

    modifier onlyInvestor() {
        require(investorShares[msg.sender] > 0, "Not an investor");
        _;
    }

    function addInvestor(address investor, uint256 shares) external onlyOwner {
        require(investor != address(0), "Invalid investor");
        require(shares > 0, "Shares must be greater than 0");
        require(investorShares[investor] == 0, "Investor already added");
        
        investors.push(investor);
        investorShares[investor] = shares;
        totalShares += shares;
    }
    
    function deposit() external payable onlyOwner {
        require(msg.value > 0, "Deposit must be greater than 0");
        require(totalShares > 0, "No investors available");
        
        totalDividends += msg.value;
        emit Deposited(msg.value);
    }
    
    function withdrawDividends() external nonReentrant onlyInvestor {
        uint256 owed = (totalDividends * investorShares[msg.sender]) / totalShares;
        uint256 claimable = owed - withdrawnDividends[msg.sender];
        require(claimable > 0, "No dividends available");
        
        withdrawnDividends[msg.sender] += claimable;
        payable(msg.sender).transfer(claimable);
        emit Withdrawn(msg.sender, claimable);
    }
    
    function getInvestors() external view returns (address[] memory) {
        return investors;
    }
    
    function getClaimableDividends(address investor) external view returns (uint256) {
        uint256 owed = (totalDividends * investorShares[investor]) / totalShares;
        return owed - withdrawnDividends[investor];
    }
}
