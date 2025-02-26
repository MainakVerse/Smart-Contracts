// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract LogisticsShipment is Ownable {
    using EnumerableSet for EnumerableSet.UintSet;
    
    struct Shipment {
        uint256 id;
        address sender;
        address receiver;
        string origin;
        string destination;
        uint256 dispatchedTime;
        uint256 deliveredTime;
        bool inTransit;
        bool isDelivered;
    }
    
    mapping(uint256 => Shipment) public shipments;
    EnumerableSet.UintSet private shipmentIds;
    uint256 public nextShipmentId;
    
    event ShipmentCreated(uint256 indexed id, address indexed sender, address indexed receiver, string origin, string destination);
    event ShipmentDispatched(uint256 indexed id, uint256 dispatchedTime);
    event ShipmentDelivered(uint256 indexed id, uint256 deliveredTime);
    
    function createShipment(address receiver, string memory origin, string memory destination) external {
        require(receiver != address(0), "Invalid receiver address");
        
        uint256 shipmentId = nextShipmentId++;
        shipments[shipmentId] = Shipment({
            id: shipmentId,
            sender: msg.sender,
            receiver: receiver,
            origin: origin,
            destination: destination,
            dispatchedTime: 0,
            deliveredTime: 0,
            inTransit: false,
            isDelivered: false
        });
        
        shipmentIds.add(shipmentId);
        emit ShipmentCreated(shipmentId, msg.sender, receiver, origin, destination);
    }
    
    function dispatchShipment(uint256 shipmentId) external onlyOwner {
        require(shipmentIds.contains(shipmentId), "Shipment does not exist");
        Shipment storage shipment = shipments[shipmentId];
        require(!shipment.inTransit, "Shipment already in transit");
        
        shipment.dispatchedTime = block.timestamp;
        shipment.inTransit = true;
        
        emit ShipmentDispatched(shipmentId, shipment.dispatchedTime);
    }
    
    function markDelivered(uint256 shipmentId) external onlyOwner {
        require(shipmentIds.contains(shipmentId), "Shipment does not exist");
        Shipment storage shipment = shipments[shipmentId];
        require(shipment.inTransit, "Shipment not in transit");
        require(!shipment.isDelivered, "Shipment already delivered");
        
        shipment.deliveredTime = block.timestamp;
        shipment.inTransit = false;
        shipment.isDelivered = true;
        
        emit ShipmentDelivered(shipmentId, shipment.deliveredTime);
    }
    
    function getShipment(uint256 shipmentId) external view returns (Shipment memory) {
        require(shipmentIds.contains(shipmentId), "Shipment does not exist");
        return shipments[shipmentId];
    }
}
