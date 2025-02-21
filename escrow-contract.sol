// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Escrow {
    address public payer;
    address public payee;
    address public arbiter;
    uint256 public amount;
    bool public isFunded;
    bool public isReleased;
    bool public isCancelled;

    event FundDeposited(address indexed payer, uint256 amount);
    event PaymentReleased(address indexed payee, uint256 amount);
    event EscrowCancelled(address indexed payer, uint256 amountRefunded);

    modifier onlyPayer() {
        require(msg.sender == payer, "Only payer can call this function");
        _;
    }

    modifier onlyArbiter() {
        require(msg.sender == arbiter, "Only arbiter can call this function");
        _;
    }

    modifier onlyWhenFunded() {
        require(isFunded, "Funds have not been deposited yet");
        _;
    }

    modifier onlyWhenNotReleased() {
        require(!isReleased, "Funds have already been released");
        _;
    }

    modifier onlyWhenNotCancelled() {
        require(!isCancelled, "Escrow has been cancelled");
        _;
    }

    constructor(address _payee, address _arbiter) payable {
        require(_payee != address(0), "Invalid payee address");
        require(_arbiter != address(0), "Invalid arbiter address");
        require(msg.value > 0, "Deposit amount must be greater than zero");
        
        payer = msg.sender;
        payee = _payee;
        arbiter = _arbiter;
        amount = msg.value;
        isFunded = true;
    }

    function releaseFunds() external onlyArbiter onlyWhenFunded onlyWhenNotReleased onlyWhenNotCancelled {
        isReleased = true;
        payable(payee).transfer(amount);
        emit PaymentReleased(payee, amount);
    }

    function cancelEscrow() external onlyArbiter onlyWhenFunded onlyWhenNotReleased onlyWhenNotCancelled {
        isCancelled = true;
        payable(payer).transfer(amount);
        emit EscrowCancelled(payer, amount);
    }
}
