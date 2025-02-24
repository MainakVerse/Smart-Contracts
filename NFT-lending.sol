// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTRentingSystem is ReentrancyGuard, Ownable {
    struct Rental {
        address lender;
        address borrower;
        address nftAddress;
        uint256 tokenId;
        uint256 rentPrice;
        uint256 startTime;
        uint256 duration;
        bool active;
    }

    mapping(address => mapping(uint256 => Rental)) public rentals;
    mapping(address => mapping(uint256 => bool)) public isLent;
    
    event NFTLent(address indexed lender, address indexed nftAddress, uint256 indexed tokenId, uint256 rentPrice, uint256 duration);
    event NFTRented(address indexed borrower, address indexed nftAddress, uint256 indexed tokenId, uint256 startTime, uint256 duration);
    event NFTReturned(address indexed nftAddress, uint256 indexed tokenId);
    
    modifier onlyLender(address nftAddress, uint256 tokenId) {
        require(rentals[nftAddress][tokenId].lender == msg.sender, "Not the lender");
        _;
    }
    
    modifier onlyBorrower(address nftAddress, uint256 tokenId) {
        require(rentals[nftAddress][tokenId].borrower == msg.sender, "Not the borrower");
        _;
    }
    
    function lendNFT(address nftAddress, uint256 tokenId, uint256 rentPrice, uint256 duration) external nonReentrant {
        require(!isLent[nftAddress][tokenId], "NFT already lent");
        require(rentPrice > 0, "Invalid rent price");
        require(duration > 0, "Invalid duration");

        IERC721 nft = IERC721(nftAddress);
        require(nft.ownerOf(tokenId) == msg.sender, "Not NFT owner");
        require(nft.getApproved(tokenId) == address(this) || nft.isApprovedForAll(msg.sender, address(this)), "Contract not approved");

        rentals[nftAddress][tokenId] = Rental({
            lender: msg.sender,
            borrower: address(0),
            nftAddress: nftAddress,
            tokenId: tokenId,
            rentPrice: rentPrice,
            startTime: 0,
            duration: duration,
            active: false
        });

        isLent[nftAddress][tokenId] = true;
        emit NFTLent(msg.sender, nftAddress, tokenId, rentPrice, duration);
    }

    function rentNFT(address nftAddress, uint256 tokenId) external payable nonReentrant {
        Rental storage rental = rentals[nftAddress][tokenId];
        require(isLent[nftAddress][tokenId], "NFT not available");
        require(rental.borrower == address(0), "Already rented");
        require(msg.value == rental.rentPrice, "Incorrect rent amount");

        rental.borrower = msg.sender;
        rental.startTime = block.timestamp;
        rental.active = true;

        payable(rental.lender).transfer(msg.value);
        emit NFTRented(msg.sender, nftAddress, tokenId, rental.startTime, rental.duration);
    }

    function returnNFT(address nftAddress, uint256 tokenId) external onlyBorrower(nftAddress, tokenId) nonReentrant {
        Rental storage rental = rentals[nftAddress][tokenId];
        require(rental.active, "NFT not rented");
        require(block.timestamp >= rental.startTime + rental.duration, "Rental period not ended");

        rental.borrower = address(0);
        rental.startTime = 0;
        rental.active = false;
        
        emit NFTReturned(nftAddress, tokenId);
    }
    
    function forceReturnNFT(address nftAddress, uint256 tokenId) external onlyLender(nftAddress, tokenId) nonReentrant {
        Rental storage rental = rentals[nftAddress][tokenId];
        require(rental.active, "NFT not rented");
        require(block.timestamp >= rental.startTime + rental.duration, "Rental period not ended");
        
        rental.borrower = address(0);
        rental.startTime = 0;
        rental.active = false;
        
        emit NFTReturned(nftAddress, tokenId);
    }
}
