// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BreedingNFT is ERC721Enumerable, Ownable {
    struct NFTAttributes {
        uint256 parent1;
        uint256 parent2;
        uint256 generation;
        uint256 genes; // Encoded genetic traits
        uint256 cooldown;
    }

    mapping(uint256 => NFTAttributes) public nftData;
    uint256 public nextTokenId = 1;
    uint256 public cooldownTime = 1 days;

    event NFTBred(address indexed owner, uint256 parent1, uint256 parent2, uint256 newTokenId, uint256 genes);

    constructor() ERC721("BreedableNFT", "BNFT") {}

    function mintNFT(uint256 genes) external onlyOwner {
        uint256 tokenId = nextTokenId++;
        _safeMint(msg.sender, tokenId);
        nftData[tokenId] = NFTAttributes(0, 0, 1, genes, block.timestamp);
    }

    function breed(uint256 parent1, uint256 parent2) external {
        require(ownerOf(parent1) == msg.sender && ownerOf(parent2) == msg.sender, "Not NFT owner");
        require(nftData[parent1].cooldown <= block.timestamp && nftData[parent2].cooldown <= block.timestamp, "NFT on cooldown");

        uint256 childGenes = _mixGenes(nftData[parent1].genes, nftData[parent2].genes);
        uint256 newTokenId = nextTokenId++;

        _safeMint(msg.sender, newTokenId);
        nftData[newTokenId] = NFTAttributes(parent1, parent2, nftData[parent1].generation + 1, childGenes, block.timestamp + cooldownTime);

        nftData[parent1].cooldown = block.timestamp + cooldownTime;
        nftData[parent2].cooldown = block.timestamp + cooldownTime;

        emit NFTBred(msg.sender, parent1, parent2, newTokenId, childGenes);
    }

    function _mixGenes(uint256 genes1, uint256 genes2) internal pure returns (uint256) {
        return (genes1 & 0xFFFFFFFF00000000) | (genes2 & 0x00000000FFFFFFFF);
    }

    function setCooldownTime(uint256 _cooldownTime) external onlyOwner {
        cooldownTime = _cooldownTime;
    }
}
