// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract VerifiableCredentialRegistry is Ownable {
    using ECDSA for bytes32;
    
    struct Credential {
        bytes32 credentialHash;
        address issuer;
        uint256 issuedAt;
        bool revoked;
    }
    
    mapping(bytes32 => Credential) public credentials;
    event CredentialIssued(bytes32 indexed credentialHash, address indexed issuer);
    event CredentialRevoked(bytes32 indexed credentialHash, address indexed issuer);
    
    function issueCredential(bytes32 credentialHash) external onlyOwner {
        require(credentials[credentialHash].issuer == address(0), "Credential already exists");
        
        credentials[credentialHash] = Credential({
            credentialHash: credentialHash,
            issuer: msg.sender,
            issuedAt: block.timestamp,
            revoked: false
        });
        
        emit CredentialIssued(credentialHash, msg.sender);
    }
    
    function revokeCredential(bytes32 credentialHash) external onlyOwner {
        require(credentials[credentialHash].issuer == msg.sender, "Not the issuer");
        require(!credentials[credentialHash].revoked, "Already revoked");
        
        credentials[credentialHash].revoked = true;
        emit CredentialRevoked(credentialHash, msg.sender);
    }
    
    function verifyCredential(bytes32 credentialHash) external view returns (bool) {
        return credentials[credentialHash].issuer != address(0) && !credentials[credentialHash].revoked;
    }
}
