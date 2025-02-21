// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract TokenizedBond is ERC20, Ownable, ReentrancyGuard {
    struct Bond {
        uint256 faceValue;
        uint256 interestRate; // Annual interest rate in basis points (100 = 1%)
        uint256 maturityDate;
        uint256 issuedSupply;
        bool isRedeemed;
    }

    Bond public bondDetails;
    mapping(address => uint256) public bondBalances;
    mapping(address => bool) public hasRedeemed;

    event BondIssued(address indexed issuer, uint256 supply, uint256 faceValue, uint256 interestRate, uint256 maturityDate);
    event BondTransferred(address indexed from, address indexed to, uint256 amount);
    event BondRedeemed(address indexed holder, uint256 amount, uint256 interest);

    constructor(
        string memory name_, 
        string memory symbol_, 
        uint256 faceValue_, 
        uint256 interestRate_, 
        uint256 maturityDate_
    ) ERC20(name_, symbol_) {
        require(maturityDate_ > block.timestamp, "Maturity date must be in the future");
        bondDetails = Bond({
            faceValue: faceValue_,
            interestRate: interestRate_,
            maturityDate: maturityDate_,
            issuedSupply: 0,
            isRedeemed: false
        });
    }

    function issueBonds(address to, uint256 amount) external onlyOwner {
        require(bondDetails.issuedSupply + amount <= totalSupply(), "Exceeds total bond supply");
        _mint(to, amount);
        bondBalances[to] += amount;
        bondDetails.issuedSupply += amount;
        emit BondIssued(msg.sender, amount, bondDetails.faceValue, bondDetails.interestRate, bondDetails.maturityDate);
    }

    function transferBonds(address to, uint256 amount) external {
        require(balanceOf(msg.sender) >= amount, "Insufficient bond balance");
        _transfer(msg.sender, to, amount);
        bondBalances[msg.sender] -= amount;
        bondBalances[to] += amount;
        emit BondTransferred(msg.sender, to, amount);
    }

    function redeemBonds() external nonReentrant {
        require(block.timestamp >= bondDetails.maturityDate, "Bonds not yet matured");
        require(balanceOf(msg.sender) > 0, "No bonds to redeem");
        require(!hasRedeemed[msg.sender], "Already redeemed");

        uint256 bondAmount = balanceOf(msg.sender);
        uint256 interest = (bondAmount * bondDetails.interestRate) / 10000; // Calculate interest
        uint256 payout = bondAmount + interest;

        hasRedeemed[msg.sender] = true;
        _burn(msg.sender, bondAmount);
        payable(msg.sender).transfer(payout);

        emit BondRedeemed(msg.sender, bondAmount, interest);
    }

    function earlyRedemption() external nonReentrant {
        require(balanceOf(msg.sender) > 0, "No bonds to redeem");
        require(block.timestamp < bondDetails.maturityDate, "Use regular redemption after maturity");

        uint256 bondAmount = balanceOf(msg.sender);
        uint256 penalty = (bondAmount * 5) / 100; // 5% penalty for early redemption
        uint256 payout = bondAmount - penalty;

        _burn(msg.sender, bondAmount);
        payable(msg.sender).transfer(payout);
    }

    receive() external payable {}
}
