// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CryptoLending is ReentrancyGuard {
    struct Loan {
        address borrower;
        uint256 amount;
        uint256 collateral;
        uint256 interestRate;
        uint256 dueDate;
        bool isActive;
    }

    IERC20 public immutable token;  // ERC20 token used for lending and borrowing
    address public admin;
    uint256 public constant interestRate = 5; // 5% interest
    uint256 public constant collateralRatio = 150; // 150% collateral requirement
    uint256 public constant loanDuration = 30 days; // Loan duration

    mapping(address => uint256) public deposits;
    mapping(address => Loan) public loans;

    event Deposited(address indexed lender, uint256 amount);
    event Borrowed(address indexed borrower, uint256 amount, uint256 collateral);
    event Repaid(address indexed borrower, uint256 amount);
    event Liquidated(address indexed borrower, uint256 collateralSeized);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    constructor(address _token) {
        token = IERC20(_token);
        admin = msg.sender;
    }

    // Deposit funds for lending
    function deposit(uint256 _amount) external nonReentrant {
        require(_amount > 0, "Deposit amount must be greater than zero");
        token.transferFrom(msg.sender, address(this), _amount);
        deposits[msg.sender] += _amount;
        emit Deposited(msg.sender, _amount);
    }

    // Borrow funds with collateral
    function borrow(uint256 _amount) external nonReentrant {
        require(_amount > 0, "Borrow amount must be greater than zero");
        uint256 requiredCollateral = (_amount * collateralRatio) / 100;
        require(token.balanceOf(msg.sender) >= requiredCollateral, "Insufficient collateral");

        token.transferFrom(msg.sender, address(this), requiredCollateral);
        loans[msg.sender] = Loan({
            borrower: msg.sender,
            amount: _amount,
            collateral: requiredCollateral,
            interestRate: interestRate,
            dueDate: block.timestamp + loanDuration,
            isActive: true
        });

        token.transfer(msg.sender, _amount);
        emit Borrowed(msg.sender, _amount, requiredCollateral);
    }

    // Repay a loan
    function repay() external nonReentrant {
        Loan storage loan = loans[msg.sender];
        require(loan.isActive, "No active loan");
        require(block.timestamp <= loan.dueDate, "Loan is overdue");

        uint256 repaymentAmount = loan.amount + ((loan.amount * loan.interestRate) / 100);
        require(token.balanceOf(msg.sender) >= repaymentAmount, "Insufficient balance to repay");

        token.transferFrom(msg.sender, address(this), repaymentAmount);
        token.transfer(msg.sender, loan.collateral);

        delete loans[msg.sender];
        emit Repaid(msg.sender, repaymentAmount);
    }

    // Liquidate a loan if overdue
    function liquidate(address _borrower) external onlyAdmin nonReentrant {
        Loan storage loan = loans[_borrower];
        require(loan.isActive, "No active loan");
        require(block.timestamp > loan.dueDate, "Loan not overdue");

        token.transfer(admin, loan.collateral);
        delete loans[_borrower];

        emit Liquidated(_borrower, loan.collateral);
    }

    // Withdraw lender funds
    function withdraw(uint256 _amount) external nonReentrant {
        require(_amount > 0, "Withdraw amount must be greater than zero");
        require(deposits[msg.sender] >= _amount, "Insufficient funds");

        deposits[msg.sender] -= _amount;
        token.transfer(msg.sender, _amount);
    }
}

