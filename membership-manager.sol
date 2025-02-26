// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DAOMembershipNFT is ERC721Enumerable, Ownable {
    uint256 public constant MAX_SUPPLY = 10000; // Max membership NFTs
    string private _baseTokenURI;
    mapping(address => bool) public hasMinted; // Ensures one NFT per member
    mapping(uint256 => bool) public revoked; // Track revoked memberships
    
    event MembershipRevoked(uint256 indexed tokenId);
    event MembershipGranted(address indexed member, uint256 tokenId);
    
    constructor(string memory baseURI) ERC721("DAOMembership", "DAOM") {
        _baseTokenURI = baseURI;
    }

    modifier onlyValidToken(uint256 tokenId) {
        require(_exists(tokenId), "Token does not exist");
        require(!revoked[tokenId], "Membership revoked");
        _;
    }

    function mint() external {
        require(totalSupply() < MAX_SUPPLY, "Max supply reached");
        require(!hasMinted[msg.sender], "Already a member");
        
        uint256 tokenId = totalSupply() + 1;
        _safeMint(msg.sender, tokenId);
        hasMinted[msg.sender] = true;
        emit MembershipGranted(msg.sender, tokenId);
    }
    
    function revokeMembership(uint256 tokenId) external onlyOwner onlyValidToken(tokenId) {
        revoked[tokenId] = true;
        emit MembershipRevoked(tokenId);
    }
    
    function isMember(address user) external view returns (bool) {
        uint256 balance = balanceOf(user);
        for (uint256 i = 0; i < balance; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(user, i);
            if (!revoked[tokenId]) return true;
        }
        return false;
    }
    
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }
    
    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }
    
    function transferFrom(address from, address to, uint256 tokenId) public override onlyValidToken(tokenId) {
        super.transferFrom(from, to, tokenId);
    }
    
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override onlyValidToken(tokenId) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}
