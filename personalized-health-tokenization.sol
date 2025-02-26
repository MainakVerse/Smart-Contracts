// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract PharmaceuticalSupplyChain is Ownable {
    using EnumerableSet for EnumerableSet.UintSet;
    
    struct MedicineBatch {
        uint256 batchId;
        string medicineName;
        address manufacturer;
        uint256 productionDate;
        uint256 expiryDate;
        string batchHash;
        bool isVerified;
    }
    
    mapping(uint256 => MedicineBatch) public batches;
    EnumerableSet.UintSet private batchIds;
    uint256 public nextBatchId;
    
    event BatchCreated(uint256 indexed batchId, string medicineName, address indexed manufacturer);
    event BatchVerified(uint256 indexed batchId);
    
    function createBatch(
        string memory medicineName,
        uint256 productionDate,
        uint256 expiryDate,
        string memory batchHash
    ) external onlyOwner {
        require(productionDate < expiryDate, "Invalid dates");
        
        uint256 batchId = nextBatchId++;
        batches[batchId] = MedicineBatch({
            batchId: batchId,
            medicineName: medicineName,
            manufacturer: msg.sender,
            productionDate: productionDate,
            expiryDate: expiryDate,
            batchHash: batchHash,
            isVerified: false
        });
        
        batchIds.add(batchId);
        emit BatchCreated(batchId, medicineName, msg.sender);
    }
    
    function verifyBatch(uint256 batchId) external onlyOwner {
        require(batchIds.contains(batchId), "Batch does not exist");
        batches[batchId].isVerified = true;
        emit BatchVerified(batchId);
    }
    
    function getBatch(uint256 batchId) external view returns (MedicineBatch memory) {
        require(batchIds.contains(batchId), "Batch does not exist");
        return batches[batchId];
    }
}
