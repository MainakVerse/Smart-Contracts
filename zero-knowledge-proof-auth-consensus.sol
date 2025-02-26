// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract ZKProofAuth is Ownable {
    using ECDSA for bytes32;
    
    bytes32 public merkleRoot;
    mapping(address => bool) public verifiedUsers;
    
    event UserVerified(address indexed user);
    
    constructor(bytes32 _merkleRoot) {
        merkleRoot = _merkleRoot;
    }
    
    function verifyIdentity(bytes32[] calldata proof, bytes32 leaf) external {
        require(!verifiedUsers[msg.sender], "Already verified");
        require(MerkleProof.verify(proof, merkleRoot, leaf), "Invalid proof");
        
        verifiedUsers[msg.sender] = true;
        emit UserVerified(msg.sender);
    }
    
    function isVerified(address user) external view returns (bool) {
        return verifiedUsers[user];
    }
    
    function updateMerkleRoot(bytes32 newRoot) external onlyOwner {
        merkleRoot = newRoot;
    }
}
