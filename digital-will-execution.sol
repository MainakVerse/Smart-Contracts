// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract DigitalWillExecution is Ownable {
    struct Beneficiary {
        address wallet;
        uint256 sharePercentage;
    }
    
    struct Will {
        address owner;
        Beneficiary[] beneficiaries;
        bool executed;
    }
    
    mapping(address => Will) public wills;
    
    event WillCreated(address indexed owner);
    event WillExecuted(address indexed owner);
    
    function createWill(Beneficiary[] memory _beneficiaries) external {
        require(wills[msg.sender].owner == address(0), "Will already exists");
        
        uint256 totalShare;
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            totalShare += _beneficiaries[i].sharePercentage;
        }
        require(totalShare == 100, "Shares must sum to 100%");
        
        wills[msg.sender] = Will({
            owner: msg.sender,
            beneficiaries: _beneficiaries,
            executed: false
        });
        emit WillCreated(msg.sender);
    }
    
    function executeWill(address _owner) external onlyOwner {
        Will storage userWill = wills[_owner];
        require(userWill.owner != address(0), "Will not found");
        require(!userWill.executed, "Will already executed");
        
        uint256 balance = address(this).balance;
        for (uint256 i = 0; i < userWill.beneficiaries.length; i++) {
            payable(userWill.beneficiaries[i].wallet).transfer((balance * userWill.beneficiaries[i].sharePercentage) / 100);
        }
        
        userWill.executed = true;
        emit WillExecuted(_owner);
    }
    
    function deposit() external payable {}
    
    function getWill(address _owner) external view returns (Will memory) {
        return wills[_owner];
    }
}
