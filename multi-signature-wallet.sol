// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract MultiSigWallet {
    address[] public owners;
    mapping(address => bool) public isOwner;
    uint public requiredApprovals;

    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
        uint approvals;
    }

    Transaction[] public transactions;
    mapping(uint => mapping(address => bool)) public approvedBy; 

    event Deposit(address indexed sender, uint amount);
    event TransactionSubmitted(uint indexed txIndex, address indexed to, uint value, bytes data);
    event TransactionApproved(uint indexed txIndex, address indexed owner);
    event TransactionRevoked(uint indexed txIndex, address indexed owner);
    event TransactionExecuted(uint indexed txIndex, address indexed to, uint value);

    modifier onlyOwner() {
        require(isOwner[msg.sender], "Not an owner");
        _;
    }

    modifier txExists(uint _txIndex) {
        require(_txIndex < transactions.length, "Transaction does not exist");
        _;
    }

    modifier notExecuted(uint _txIndex) {
        require(!transactions[_txIndex].executed, "Transaction already executed");
        _;
    }

    modifier notApproved(uint _txIndex) {
        require(!approvedBy[_txIndex][msg.sender], "Transaction already approved by this owner");
        _;
    }

    constructor(address[] memory _owners, uint _requiredApprovals) {
        require(_owners.length > 0, "At least one owner required");
        require(_requiredApprovals > 0 && _requiredApprovals <= _owners.length, "Invalid required approvals count");

        for (uint i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "Invalid owner address");
            require(!isOwner[owner], "Owner is already added");
            isOwner[owner] = true;
            owners.push(owner);
        }

        requiredApprovals = _requiredApprovals;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    function submitTransaction(address _to, uint _value, bytes memory _data) external onlyOwner {
        uint txIndex = transactions.length;
        transactions.push(Transaction({
            to: _to,
            value: _value,
            data: _data,
            executed: false,
            approvals: 0
        }));

        emit TransactionSubmitted(txIndex, _to, _value, _data);
    }

    function approveTransaction(uint _txIndex) external onlyOwner txExists(_txIndex) notExecuted(_txIndex) notApproved(_txIndex) {
        transactions[_txIndex].approvals += 1;
        approvedBy[_txIndex][msg.sender] = true;

        emit TransactionApproved(_txIndex, msg.sender);
    }

    function revokeApproval(uint _txIndex) external onlyOwner txExists(_txIndex) notExecuted(_txIndex) {
        require(approvedBy[_txIndex][msg.sender], "Transaction not approved by this owner");

        transactions[_txIndex].approvals -= 1;
        approvedBy[_txIndex][msg.sender] = false;

        emit TransactionRevoked(_txIndex, msg.sender);
    }

    function executeTransaction(uint _txIndex) external onlyOwner txExists(_txIndex) notExecuted(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];
        require(transaction.approvals >= requiredApprovals, "Not enough approvals");

        transaction.executed = true;
        (bool success, ) = transaction.to.call{value: transaction.value}(transaction.data);
        require(success, "Transaction execution failed");

        emit TransactionExecuted(_txIndex, transaction.to, transaction.value);
    }

    function getOwners() external view returns (address[] memory) {
        return owners;
    }

    function getTransactionCount() external view returns (uint) {
        return transactions.length;
    }

    function getTransaction(uint _txIndex)
        external
        view
        returns (address to, uint value, bytes memory data, bool executed, uint approvals)
    {
        Transaction storage transaction = transactions[_txIndex];
        return (transaction.to, transaction.value, transaction.data, transaction.executed, transaction.approvals);
    }
}
