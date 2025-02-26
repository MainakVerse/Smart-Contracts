// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract MultiPartyKeyRecovery is Ownable {
    using ECDSA for bytes32;
    
    struct RecoveryRequest {
        address user;
        bytes32 recoveryHash;
        uint256 approvals;
        bool recovered;
    }
    
    mapping(address => bool) public guardians;
    mapping(bytes32 => RecoveryRequest) public recoveryRequests;
    mapping(bytes32 => mapping(address => bool)) public approvals;
    uint256 public requiredApprovals;
    
    event GuardianAdded(address indexed guardian);
    event GuardianRemoved(address indexed guardian);
    event RecoveryRequested(address indexed user, bytes32 indexed recoveryHash);
    event RecoveryApproved(address indexed guardian, bytes32 indexed recoveryHash);
    event KeyRecovered(address indexed user, bytes32 indexed recoveryHash);
    
    constructor(uint256 _requiredApprovals) {
        requiredApprovals = _requiredApprovals;
    }
    
    modifier onlyGuardian() {
        require(guardians[msg.sender], "Not a guardian");
        _;
    }
    
    function addGuardian(address guardian) external onlyOwner {
        guardians[guardian] = true;
        emit GuardianAdded(guardian);
    }
    
    function removeGuardian(address guardian) external onlyOwner {
        guardians[guardian] = false;
        emit GuardianRemoved(guardian);
    }
    
    function requestRecovery(bytes32 recoveryHash) external {
        require(recoveryRequests[recoveryHash].user == address(0), "Request already exists");
        
        recoveryRequests[recoveryHash] = RecoveryRequest({
            user: msg.sender,
            recoveryHash: recoveryHash,
            approvals: 0,
            recovered: false
        });
        
        emit RecoveryRequested(msg.sender, recoveryHash);
    }
    
    function approveRecovery(bytes32 recoveryHash) external onlyGuardian {
        RecoveryRequest storage request = recoveryRequests[recoveryHash];
        require(request.user != address(0), "Request does not exist");
        require(!request.recovered, "Already recovered");
        require(!approvals[recoveryHash][msg.sender], "Already approved");
        
        approvals[recoveryHash][msg.sender] = true;
        request.approvals++;
        emit RecoveryApproved(msg.sender, recoveryHash);
        
        if (request.approvals >= requiredApprovals) {
            request.recovered = true;
            emit KeyRecovered(request.user, recoveryHash);
        }
    }
}
