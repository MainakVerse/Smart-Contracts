// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GameCurrency is ERC20, Ownable {
    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {
        _mint(msg.sender, 1000000 * 10 ** decimals()); // Initial supply
    }

    function mint(address _to, uint256 _amount) external onlyOwner {
        _mint(_to, _amount);
    }
}

contract OnChainGameEconomy is Ownable {
    GameCurrency public gold;
    GameCurrency public gems;
    IERC721 public gameNFT;
    
    struct Listing {
        address seller;
        uint256 price;
        bool isForGold;
        bool isActive;
    }

    mapping(uint256 => Listing) public marketplace;
    uint256 public tradeFeePercentage = 5; // 5% marketplace fee

    event ItemListed(address indexed seller, uint256 indexed tokenId, uint256 price, bool isForGold);
    event ItemSold(address indexed buyer, uint256 indexed tokenId, uint256 price, bool isForGold);
    
    constructor(address _goldToken, address _gemToken, address _nftContract) {
        gold = GameCurrency(_goldToken);
        gems = GameCurrency(_gemToken);
        gameNFT = IERC721(_nftContract);
    }

    function listItem(uint256 _tokenId, uint256 _price, bool _isForGold) external {
        require(gameNFT.ownerOf(_tokenId) == msg.sender, "You do not own this NFT");
        require(_price > 0, "Price must be greater than zero");

        gameNFT.transferFrom(msg.sender, address(this), _tokenId);
        marketplace[_tokenId] = Listing(msg.sender, _price, _isForGold, true);

        emit ItemListed(msg.sender, _tokenId, _price, _isForGold);
    }

    function buyItem(uint256 _tokenId) external {
        Listing storage item = marketplace[_tokenId];
        require(item.isActive, "Item is not available for sale");

        uint256 fee = (item.price * tradeFeePercentage) / 100;
        uint256 finalPrice = item.price + fee;

        if (item.isForGold) {
            require(gold.transferFrom(msg.sender, address(this), finalPrice), "Gold transfer failed");
            gold.transfer(item.seller, item.price);
        } else {
            require(gems.transferFrom(msg.sender, address(this), finalPrice), "Gems transfer failed");
            gems.transfer(item.seller, item.price);
        }

        gameNFT.transferFrom(address(this), msg.sender, _tokenId);
        item.isActive = false;

        emit ItemSold(msg.sender, _tokenId, item.price, item.isForGold);
    }

    function updateTradeFee(uint256 _newFee) external onlyOwner {
        require(_newFee <= 10, "Fee too high"); // Max 10% fee
        tradeFeePercentage = _newFee;
    }
}
