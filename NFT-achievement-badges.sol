// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AchievementBadge is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _badgeIds;

    // Mapping of badge IDs to their owners
    mapping(address => mapping(uint256 => bool)) public userBadges;

    // Mapping of badge IDs to their metadata
    mapping(uint256 => string) public badgeMetadata;

    constructor() ERC721("Achievement Badge", "AB") {}

    // Function to mint a new badge
    function mintBadge(address recipient, string memory metadata) public onlyOwner {
        _badgeIds.increment();
        uint256 newBadgeId = _badgeIds.current();

        _mint(recipient, newBadgeId);
        badgeMetadata[newBadgeId] = metadata;
        userBadges[recipient][newBadgeId] = true;

        _setTokenURI(newBadgeId, metadata);
    }

    // Override transfer function to prevent transfers
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        revert("Transferring achievement badges is not allowed");
    }

    // Override safeTransferFrom function to prevent transfers
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        revert("Transferring achievement badges is not allowed");
    }

    // Function to check if a user has a specific badge
    function hasBadge(address user, uint256 badgeId) public view returns (bool) {
        return userBadges[user][badgeId];
    }
}
