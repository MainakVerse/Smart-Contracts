// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract MedicalRecordManagement is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;
    
    struct MedicalRecord {
        uint256 id;
        address patient;
        string dataHash;
        uint256 timestamp;
    }
    
    mapping(uint256 => MedicalRecord) public records;
    mapping(address => EnumerableSet.AddressSet) private authorizedViewers;
    EnumerableSet.AddressSet private patients;
    uint256 public nextRecordId;
    
    event RecordAdded(uint256 indexed id, address indexed patient, string dataHash);
    event ViewerAuthorized(address indexed patient, address indexed viewer);
    event ViewerRevoked(address indexed patient, address indexed viewer);
    
    function addRecord(string memory dataHash) external {
        uint256 recordId = nextRecordId++;
        records[recordId] = MedicalRecord({
            id: recordId,
            patient: msg.sender,
            dataHash: dataHash,
            timestamp: block.timestamp
        });
        
        patients.add(msg.sender);
        emit RecordAdded(recordId, msg.sender, dataHash);
    }
    
    function authorizeViewer(address viewer) external {
        require(viewer != address(0), "Invalid viewer address");
        authorizedViewers[msg.sender].add(viewer);
        emit ViewerAuthorized(msg.sender, viewer);
    }
    
    function revokeViewer(address viewer) external {
        require(authorizedViewers[msg.sender].contains(viewer), "Viewer not authorized");
        authorizedViewers[msg.sender].remove(viewer);
        emit ViewerRevoked(msg.sender, viewer);
    }
    
    function getRecord(uint256 recordId) external view returns (MedicalRecord memory) {
        require(records[recordId].patient == msg.sender || authorizedViewers[records[recordId].patient].contains(msg.sender), "Not authorized");
        return records[recordId];
    }
}
