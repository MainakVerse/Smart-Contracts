// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract LootBox is Ownable, VRFConsumerBase {
    struct LootItem {
        address contractAddress; // ERC-20 or ERC-721
        uint256 tokenId; // 0 for ERC-20, specific ID for ERC-721
        uint256 amount; // Amount for ERC-20, 1 for ERC-721
        bool isNFT;
    }

    LootItem[] public lootPool;
    bytes32 internal keyHash;
    uint256 internal fee;
    mapping(bytes32 => address) private requestToPlayer;

    event LootBoxOpened(address indexed player, address rewardContract, uint256 tokenId, uint256 amount, bool isNFT);

    constructor(address _vrfCoordinator, address _linkToken, bytes32 _keyHash, uint256 _fee)
        VRFConsumerBase(_vrfCoordinator, _linkToken) {
        keyHash = _keyHash;
        fee = _fee;
    }

    function addLootItem(address _contractAddress, uint256 _tokenId, uint256 _amount, bool _isNFT) external onlyOwner {
        lootPool.push(LootItem(_contractAddress, _tokenId, _amount, _isNFT));
    }

    function openLootBox() external returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK for randomness");
        requestId = requestRandomness(keyHash, fee);
        requestToPlayer[requestId] = msg.sender;
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        address player = requestToPlayer[requestId];
        require(player != address(0), "Invalid player");

        uint256 lootIndex = randomness % lootPool.length;
        LootItem memory item = lootPool[lootIndex];

        if (item.isNFT) {
            IERC721(item.contractAddress).safeTransferFrom(address(this), player, item.tokenId);
        } else {
            require(IERC20(item.contractAddress).transfer(player, item.amount), "ERC-20 transfer failed");
        }

        emit LootBoxOpened(player, item.contractAddress, item.tokenId, item.amount, item.isNFT);
    }

    function withdrawLink() external onlyOwner {
        IERC20(LINK).transfer(owner(), LINK.balanceOf(address(this)));
    }
}
