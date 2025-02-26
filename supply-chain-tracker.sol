// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract SupplyChainTracking is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;
    
    enum Status { Created, InTransit, Delivered, Verified }
    
    struct Product {
        uint256 id;
        string name;
        address origin;
        address currentHolder;
        Status status;
        uint256 timestamp;
    }
    
    mapping(uint256 => Product) public products;
    EnumerableSet.UintSet private productIds;
    uint256 public nextProductId;
    
    event ProductCreated(uint256 indexed id, string name, address indexed origin);
    event ProductStatusUpdated(uint256 indexed id, Status status, address indexed holder);
    
    function createProduct(string memory name) external onlyOwner {
        uint256 productId = nextProductId++;
        products[productId] = Product({
            id: productId,
            name: name,
            origin: msg.sender,
            currentHolder: msg.sender,
            status: Status.Created,
            timestamp: block.timestamp
        });
        
        productIds.add(productId);
        emit ProductCreated(productId, name, msg.sender);
    }
    
    function updateStatus(uint256 productId, Status newStatus, address newHolder) external onlyOwner {
        require(productIds.contains(productId), "Product does not exist");
        require(newHolder != address(0), "Invalid holder address");
        
        Product storage product = products[productId];
        product.status = newStatus;
        product.currentHolder = newHolder;
        product.timestamp = block.timestamp;
        
        emit ProductStatusUpdated(productId, newStatus, newHolder);
    }
    
    function getProduct(uint256 productId) external view returns (Product memory) {
        require(productIds.contains(productId), "Product does not exist");
        return products[productId];
    }
}
