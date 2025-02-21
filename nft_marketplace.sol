// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NFTMarketplace is ERC721URIStorage, Ownable, ReentrancyGuard {
    struct Listing {
        address seller;
        uint256 price;
        bool isListed;
    }

    struct Auction {
        address highestBidder;
        uint256 highestBid;
        uint256 endTime;
        bool isActive;
    }

    mapping(uint256 => Listing) public listings;
    mapping(uint256 => Auction) public auctions;
    mapping(uint256 => mapping(address => uint256)) public bids;
    
    event NFTListed(uint256 indexed tokenId, address seller, uint256 price);
    event NFTSold(uint256 indexed tokenId, address buyer, uint256 price);
    event NFTAuctionStarted(uint256 indexed tokenId, uint256 endTime);
    event NFTBidPlaced(uint256 indexed tokenId, address bidder, uint256 amount);
    event NFTAuctionEnded(uint256 indexed tokenId, address winner, uint256 amount);
    
    constructor() ERC721("NFT Marketplace", "NFTM") {}
    
    function mintNFT(string memory tokenURI, uint256 tokenId) external onlyOwner {
        _mint(msg.sender, tokenId);
        _setTokenURI(tokenId, tokenURI);
    }
    
    function listNFT(uint256 tokenId, uint256 price) external {
        require(ownerOf(tokenId) == msg.sender, "Not NFT owner");
        require(price > 0, "Price must be greater than zero");
        listings[tokenId] = Listing(msg.sender, price, true);
        emit NFTListed(tokenId, msg.sender, price);
    }
    
    function buyNFT(uint256 tokenId) external payable nonReentrant {
        Listing memory item = listings[tokenId];
        require(item.isListed, "NFT not listed");
        require(msg.value >= item.price, "Insufficient payment");
        
        payable(item.seller).transfer(msg.value);
        _transfer(item.seller, msg.sender, tokenId);
        listings[tokenId].isListed = false;
        emit NFTSold(tokenId, msg.sender, item.price);
    }
    
    function startAuction(uint256 tokenId, uint256 duration) external {
        require(ownerOf(tokenId) == msg.sender, "Not NFT owner");
        require(!auctions[tokenId].isActive, "Auction already active");
        
        auctions[tokenId] = Auction(address(0), 0, block.timestamp + duration, true);
        emit NFTAuctionStarted(tokenId, block.timestamp + duration);
    }
    
    function placeBid(uint256 tokenId) external payable {
        Auction storage auction = auctions[tokenId];
        require(auction.isActive, "Auction not active");
        require(block.timestamp < auction.endTime, "Auction ended");
        require(msg.value > auction.highestBid, "Bid too low");
        
        if (auction.highestBid > 0) {
            payable(auction.highestBidder).transfer(auction.highestBid);
        }
        
        auction.highestBidder = msg.sender;
        auction.highestBid = msg.value;
        emit NFTBidPlaced(tokenId, msg.sender, msg.value);
    }
    
    function endAuction(uint256 tokenId) external {
        Auction storage auction = auctions[tokenId];
        require(auction.isActive, "Auction not active");
        require(block.timestamp >= auction.endTime, "Auction not yet ended");
        
        auction.isActive = false;
        if (auction.highestBid > 0) {
            payable(ownerOf(tokenId)).transfer(auction.highestBid);
            _transfer(ownerOf(tokenId), auction.highestBidder, tokenId);
        }
        emit NFTAuctionEnded(tokenId, auction.highestBidder, auction.highestBid);
    }
}
