// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract TaxWithholding {
    address public owner;
    uint256 public taxRate; // Tax percentage (e.g., 5 for 5%)
    uint256 public totalCollectedTaxes;

    mapping(address => bool) public isTaxExempt;
    mapping(address => uint256) public balances;

    event TaxRateUpdated(uint256 newRate);
    event TaxExemptUpdated(address indexed account, bool isExempt);
    event TaxWithheld(address indexed from, address indexed to, uint256 amount, uint256 taxAmount);
    event WithdrawTaxes(address indexed admin, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can execute");
        _;
    }

    constructor(uint256 _taxRate) {
        require(_taxRate <= 100, "Invalid tax rate");
        owner = msg.sender;
        taxRate = _taxRate;
    }

    function updateTaxRate(uint256 _newRate) external onlyOwner {
        require(_newRate <= 100, "Invalid tax rate");
        taxRate = _newRate;
        emit TaxRateUpdated(_newRate);
    }

    function setTaxExempt(address _account, bool _status) external onlyOwner {
        isTaxExempt[_account] = _status;
        emit TaxExemptUpdated(_account, _status);
    }

    function transfer(address _to, uint256 _amount) external {
        require(_to != address(0), "Invalid recipient");
        require(balances[msg.sender] >= _amount, "Insufficient balance");

        uint256 taxAmount = 0;
        if (!isTaxExempt[msg.sender] && !isTaxExempt[_to]) {
            taxAmount = (_amount * taxRate) / 100;
        }

        uint256 finalAmount = _amount - taxAmount;
        balances[msg.sender] -= _amount;
        balances[_to] += finalAmount;
        totalCollectedTaxes += taxAmount;

        emit TaxWithheld(msg.sender, _to, finalAmount, taxAmount);
    }

    function withdrawCollectedTaxes() external onlyOwner {
       
