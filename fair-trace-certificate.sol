// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract FairTradeCertification is Ownable {
    using EnumerableSet for EnumerableSet.UintSet;
    
    struct Product {
        uint256 id;
        address producer;
        string description;
        string origin;
        bool isCertified;
    }
    
    mapping(uint256 => Product) public products;
    EnumerableSet.UintSet private productIds;
    uint256 public nextProductId;
    
    event ProductRegistered(uint256 indexed id, address indexed producer, string description, string origin);
    event ProductCertified(uint256 indexed id, bool isCertified);
    
    function registerProduct(string memory description, string memory origin) external {
        uint256 productId = nextProductId++;
        products[productId] = Product({
            id: productId,
            producer: msg.sender,
            description: description,
            origin: origin,
            isCertified: false
        });
        
        productIds.add(productId);
        emit ProductRegistered(productId, msg.sender, description, origin);
    }
    
    function certifyProduct(uint256 productId) external onlyOwner {
        require(productIds.contains(productId), "Product does not exist");
        Product storage product = products[productId];
        require(!product.isCertified, "Product already certified");
        
        product.isCertified = true;
        emit ProductCertified(productId, true);
    }
    
    function getProduct(uint256 productId) external view returns (Product memory) {
        require(productIds.contains(productId), "Product does not exist");
        return products[productId];
    }
}
