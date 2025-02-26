// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract CarbonCreditTrading is Ownable {
    using EnumerableSet for EnumerableSet.UintSet;
    
    struct CarbonCredit {
        uint256 id;
        address owner;
        uint256 amount;
        bool isListed;
        uint256 price;
    }
    
    mapping(uint256 => CarbonCredit) public credits;
    EnumerableSet.UintSet private creditIds;
    uint256 public nextCreditId;
    
    event CreditIssued(uint256 indexed id, address indexed owner, uint256 amount);
    event CreditListed(uint256 indexed id, uint256 price);
    event CreditPurchased(uint256 indexed id, address indexed buyer, uint256 price);
    
    function issueCredit(address recipient, uint256 amount) external onlyOwner {
        require(recipient != address(0), "Invalid recipient");
        require(amount > 0, "Amount must be greater than zero");
        
        uint256 creditId = nextCreditId++;
        credits[creditId] = CarbonCredit({
            id: creditId,
            owner: recipient,
            amount: amount,
            isListed: false,
            price: 0
        });
        
        creditIds.add(creditId);
        emit CreditIssued(creditId, recipient, amount);
    }
    
    function listCredit(uint256 creditId, uint256 price) external {
        require(creditIds.contains(creditId), "Credit does not exist");
        CarbonCredit storage credit = credits[creditId];
        require(msg.sender == credit.owner, "Not the owner");
        require(!credit.isListed, "Already listed");
        require(price > 0, "Price must be greater than zero");
        
        credit.isListed = true;
        credit.price = price;
        
        emit CreditListed(creditId, price);
    }
    
    function purchaseCredit(uint256 creditId) external payable {
        require(creditIds.contains(creditId), "Credit does not exist");
        CarbonCredit storage credit = credits[creditId];
        require(credit.isListed, "Not listed for sale");
        require(msg.value >= credit.price, "Insufficient payment");
        
        address seller = credit.owner;
        credit.owner = msg.sender;
        credit.isListed = false;
        credit.price = 0;
        
        payable(seller).transfer(msg.value);
        
        emit CreditPurchased(creditId, msg.sender, msg.value);
    }
    
    function getCredit(uint256 creditId) external view returns (CarbonCredit memory) {
        require(creditIds.contains(creditId), "Credit does not exist");
        return credits[creditId];
    }
}
