// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract LandRegistry is Ownable {
    using EnumerableSet for EnumerableSet.UintSet;
    
    struct Land {
        uint256 id;
        address owner;
        string location;
        uint256 area;
        bool isRegistered;
    }
    
    mapping(uint256 => Land) public lands;
    EnumerableSet.UintSet private landIds;
    uint256 public nextLandId;
    
    event LandRegistered(uint256 indexed id, address indexed owner, string location, uint256 area);
    event LandTransferred(uint256 indexed id, address indexed previousOwner, address indexed newOwner);
    
    function registerLand(string memory location, uint256 area) external {
        require(area > 0, "Area must be greater than zero");
        
        uint256 landId = nextLandId++;
        lands[landId] = Land({
            id: landId,
            owner: msg.sender,
            location: location,
            area: area,
            isRegistered: true
        });
        
        landIds.add(landId);
        emit LandRegistered(landId, msg.sender, location, area);
    }
    
    function transferLand(uint256 landId, address newOwner) external {
        require(landIds.contains(landId), "Land does not exist");
        Land storage land = lands[landId];
        require(msg.sender == land.owner, "Only the owner can transfer");
        require(newOwner != address(0), "Invalid new owner");
        
        address previousOwner = land.owner;
        land.owner = newOwner;
        
        emit LandTransferred(landId, previousOwner, newOwner);
    }
    
    function getLand(uint256 landId) external view returns (Land memory) {
        require(landIds.contains(landId), "Land does not exist");
        return lands[landId];
    }
}
