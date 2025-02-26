// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RealEstateLeaseAgreement is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    struct Lease {
        address landlord;
        address tenant;
        uint256 propertyId;
        uint256 rentAmount;
        uint256 depositAmount;
        uint256 leaseStart;
        uint256 leaseEnd;
        bool active;
    }
    
    IERC721 public propertyNFT;
    mapping(uint256 => Lease) public leases;
    EnumerableSet.AddressSet private tenants;
    
    event LeaseCreated(uint256 indexed propertyId, address indexed landlord, address indexed tenant, uint256 rentAmount, uint256 leaseEnd);
    event LeaseTerminated(uint256 indexed propertyId, address indexed tenant);
    event RentPaid(uint256 indexed propertyId, address indexed tenant, uint256 amount);
    
    constructor(address _propertyNFT) {
        propertyNFT = IERC721(_propertyNFT);
    }
    
    modifier onlyLandlord(uint256 propertyId) {
        require(leases[propertyId].landlord == msg.sender, "Not the landlord");
        _;
    }
    
    function createLease(
        uint256 propertyId,
        address tenant,
        uint256 rentAmount,
        uint256 depositAmount,
        uint256 leaseDuration
    ) external {
        require(propertyNFT.ownerOf(propertyId) == msg.sender, "Not property owner");
        require(leases[propertyId].active == false, "Lease already exists");
        
        leases[propertyId] = Lease({
            landlord: msg.sender,
            tenant: tenant,
            propertyId: propertyId,
            rentAmount: rentAmount,
            depositAmount: depositAmount,
            leaseStart: block.timestamp,
            leaseEnd: block.timestamp + leaseDuration,
            active: true
        });
        
        tenants.add(tenant);
        emit LeaseCreated(propertyId, msg.sender, tenant, rentAmount, leases[propertyId].leaseEnd);
    }
    
    function payRent(uint256 propertyId) external payable {
        Lease storage lease = leases[propertyId];
        require(lease.active, "Lease inactive");
        require(lease.tenant == msg.sender, "Not the tenant");
        require(msg.value == lease.rentAmount, "Incorrect rent amount");
        
        payable(lease.landlord).transfer(msg.value);
        emit RentPaid(propertyId, msg.sender, msg.value);
    }
    
    function terminateLease(uint256 propertyId) external onlyLandlord(propertyId) {
        Lease storage lease = leases[propertyId];
        require(lease.active, "Lease already terminated");
        
        lease.active = false;
        tenants.remove(lease.tenant);
        emit LeaseTerminated(propertyId, lease.tenant);
    }
    
    function getTenantStatus(address tenant) external view returns (bool) {
        return tenants.contains(tenant);
    }
}
