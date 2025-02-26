// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract AgricultureYieldTokenization is ERC20, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;
    
    struct YieldContract {
        uint256 id;
        address farmer;
        uint256 yieldAmount;
        uint256 pricePerUnit;
        uint256 maturityDate;
        bool active;
    }
    
    mapping(uint256 => YieldContract) public yieldContracts;
    EnumerableSet.UintSet private contractIds;
    uint256 public nextContractId;
    
    event YieldContractCreated(uint256 indexed id, address indexed farmer, uint256 yieldAmount, uint256 pricePerUnit, uint256 maturityDate);
    event YieldPurchased(uint256 indexed id, address indexed buyer, uint256 amount);
    event YieldRedeemed(uint256 indexed id, address indexed buyer);
    
    constructor() ERC20("FarmYieldToken", "FYT") {}
    
    function createYieldContract(uint256 yieldAmount, uint256 pricePerUnit, uint256 maturityDate) external {
        require(yieldAmount > 0, "Yield amount must be greater than zero");
        require(pricePerUnit > 0, "Price per unit must be greater than zero");
        require(maturityDate > block.timestamp, "Maturity date must be in the future");
        
        uint256 contractId = nextContractId++;
        yieldContracts[contractId] = YieldContract({
            id: contractId,
            farmer: msg.sender,
            yieldAmount: yieldAmount,
            pricePerUnit: pricePerUnit,
            maturityDate: maturityDate,
            active: true
        });
        
        contractIds.add(contractId);
        emit YieldContractCreated(contractId, msg.sender, yieldAmount, pricePerUnit, maturityDate);
    }
    
    function purchaseYield(uint256 contractId, uint256 amount) external payable {
        require(contractIds.contains(contractId), "Contract does not exist");
        YieldContract storage yc = yieldContracts[contractId];
        require(yc.active, "Contract is inactive");
        require(msg.value == amount * yc.pricePerUnit, "Incorrect payment");
        require(yc.yieldAmount >= amount, "Not enough yield available");
        
        yc.yieldAmount -= amount;
        _mint(msg.sender, amount);
        
        emit YieldPurchased(contractId, msg.sender, amount);
    }
    
    function redeemYield(uint256 contractId) external {
        require(contractIds.contains(contractId), "Contract does not exist");
        YieldContract storage yc = yieldContracts[contractId];
        require(block.timestamp >= yc.maturityDate, "Yield not yet mature");
        require(yc.active, "Contract is inactive");
        
        yc.active = false;
        emit YieldRedeemed(contractId, msg.sender);
    }
}
