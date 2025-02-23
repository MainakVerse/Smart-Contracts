Creating a robust and optimized NFT Marketplace smart contract in Solidity involves implementing functionalities for listing, buying, selling, and auctioning NFTs. The contract must adhere to the ERC-721 standard for NFTs and ensure security, efficiency, and flexibility. Below is a comprehensive implementation:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NFTMarketplace is ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _listingIdCounter;
    Counters.Counter private _auctionIdCounter;

    enum ListingStatus { Active, Sold, Cancelled }
    enum AuctionStatus { Active, Ended, Cancelled }

    struct Listing {
        uint256 listingId;
        address nftContract;
        uint256 tokenId;
        address payable seller;
        uint256 price;
        ListingStatus status;
    }

    struct Auction {
        uint256 auctionId;
        address nftContract;
        uint256 tokenId;
        address payable seller;
        uint256 startingPrice;
        uint256 highestBid;
        address payable highestBidder;
        uint256 endTime;
        AuctionStatus status;
    }

    mapping(uint256 => Listing) private listings;
    mapping(uint256 => Auction) private auctions;
    mapping(address => uint256) private pendingWithdrawals;

    event NFTListed(
        uint256 indexed listingId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        uint256 price
    );

    event NFTSold(
        uint256 indexed listingId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address buyer,
        uint256 price
    );

    event ListingCancelled(
        uint256 indexed listingId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller
    );

    event AuctionCreated(
        uint256 indexed auctionId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        uint256 startingPrice,
        uint256 endTime
    );

    event BidPlaced(
        uint256 indexed auctionId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address bidder,
        uint256 bidAmount
    );

    event AuctionEnded(
        uint256 indexed auctionId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address winner,
        uint256 winningBid
    );

    event AuctionCancelled(
        uint256 indexed auctionId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller
    );

    modifier onlySeller(address nftContract, uint256 tokenId) {
        require(
            IERC721(nftContract).ownerOf(tokenId) == msg.sender,
            "Caller is not the owner"
        );
        _;
    }

    modifier isListed(uint256 listingId) {
        require(
            listings[listingId].status == ListingStatus.Active,
            "Listing is not active"
        );
        _;
    }

    modifier isAuctionActive(uint256 auctionId) {
        require(
            auctions[auctionId].status == AuctionStatus.Active,
            "Auction is not active"
        );
        require(
            block.timestamp < auctions[auctionId].endTime,
            "Auction has ended"
        );
        _;
    }

    function listNFT(
        address nftContract,
        uint256 tokenId,
        uint256 price
    ) external nonReentrant onlySeller(nftContract, tokenId) {
        require(price > 0, "Price must be greater than zero");

        _listingIdCounter.increment();
        uint256 listingId = _listingIdCounter.current();

        listings[listingId] = Listing({
            listingId: listingId,
            nftContract: nftContract,
            tokenId: tokenId,
            seller: payable(msg.sender),
            price: price,
            status: ListingStatus.Active
        });

        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

        emit NFTListed(listingId, nftContract, tokenId, msg.sender, price);
    }

    function buyNFT(uint256 listingId)
        external
        payable
        nonReentrant
        isListed(listingId)
    {
        Listing storage listing = listings[listingId];
        require(msg.value >= listing.price, "Insufficient payment");

        listing.status = ListingStatus.Sold;
        pendingWithdrawals[listing.seller] += msg.value;

        IERC721(listing.nftContract).transferFrom(
            address(this),
            msg.sender,
            listing.tokenId
        );

        emit NFTSold(
            listingId,
            listing.nftContract,
            listing.tokenId,
            msg.sender,
            listing.price
        );
    }

    function cancelListing(uint256 listingId)
        external
        nonReentrant
        isListed(listingId)
    {
        Listing storage listing = listings[listingId];
        require(
            listing.seller == msg.sender,
            "Only the seller can cancel the listing"
        );

        listing.status = ListingStatus.Cancelled;

        IERC721(listing.nftContract).transferFrom(
            address(this),
            msg.sender,
            listing.tokenId
        );

        emit ListingCancelled(
            listingId,
            listing.nftContract,
            listing.tokenId,
            msg.sender
        );
    }

    function createAuction(
        address nftContract,
        uint256 tokenId,
        uint256 startingPrice,
        uint256 duration
    ) external nonReentrant onlySeller(nftContract, tokenId) {
        require(startingPrice > 0, "Starting price must be greater than zero");
        require(duration > 0, "Duration must be greater than zero");

        _auctionIdCounter.increment();
        uint256 auctionId = _auctionIdCounter.current();

        auctions[auctionId] = Auction({
            auctionId: auctionId,
            nftContract: nftContract,
            tokenId: tokenId,
            seller: payable(msg.sender),
            startingPrice: startingPrice,
            highestBid: 0,
            highestBidder: payable(address(0)),
            endTime: block.timestamp + duration,
            status: AuctionStatus.Active
        });

        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

        emit AuctionCreated(
            auctionId,
            nftContract,
            tokenId,
            msg.sender,
            startingPrice,
            block.timestamp + duration
        );
    }

    function placeBid(uint256 auctionId)
        external
        payable
        nonReentrant
        isAuctionActive(auctionId)
    {
        Auction storage auction = auctions[auctionId];
        require(
            msg.value > auction.highestBid,
            "Bid must be higher than the current highest bid"
        );
        require(
            msg.value >= auction.startingPrice,
            "Bid must be at least the starting price"
        );

        if (auction.highestBidder != address(0)) {
            pendingWithdrawals[auction.highestBidder] += auction.highestBid;
        }

        auction.highestBid = msg.value;
        auction.highestBidder = payable(msg.sender);

        emit BidPlaced(
            auctionId,
            auction.nftContract,
            auction.tokenId,
            msg.sender,
            msg.value
        );
    }

    function endAuction(uint256 
