// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTHealthCertifications is ERC721URIStorage, Ownable {
    uint256 private _tokenIdCounter;
    mapping(uint256 => string) private _certifications;
    mapping(address => uint256[]) private _ownedCertificates;
    
    event CertificationIssued(address indexed recipient, uint256 indexed tokenId, string metadataURI);
    
    constructor() ERC721("HealthCertification", "HEALTH") {}
    
    function issueCertification(address recipient, string memory metadataURI) external onlyOwner {
        uint256 tokenId = _tokenIdCounter++;
        _mint(recipient, tokenId);
        _setTokenURI(tokenId, metadataURI);
        _certifications[tokenId] = metadataURI;
        _ownedCertificates[recipient].push(tokenId);
        
        emit CertificationIssued(recipient, tokenId, metadataURI);
    }
    
    function getCertification(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId), "Certification does not exist");
        return _certifications[tokenId];
    }
    
    function getOwnedCertificates(address owner) external view returns (uint256[] memory) {
        return _ownedCertificates[owner];
    }
}
