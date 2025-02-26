// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract AIResumeVerification is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;
    
    struct Resume {
        uint256 id;
        address candidate;
        string dataHash;
        bool verified;
    }
    
    mapping(uint256 => Resume) public resumes;
    mapping(address => EnumerableSet.AddressSet) private authorizedVerifiers;
    uint256 public nextResumeId;
    
    event ResumeSubmitted(uint256 indexed id, address indexed candidate, string dataHash);
    event ResumeVerified(uint256 indexed id, address indexed verifier);
    event VerifierAuthorized(address indexed candidate, address indexed verifier);
    event VerifierRevoked(address indexed candidate, address indexed verifier);
    
    function submitResume(string memory dataHash) external {
        uint256 resumeId = nextResumeId++;
        resumes[resumeId] = Resume({
            id: resumeId,
            candidate: msg.sender,
            dataHash: dataHash,
            verified: false
        });
        emit ResumeSubmitted(resumeId, msg.sender, dataHash);
    }
    
    function authorizeVerifier(address verifier) external {
        require(verifier != address(0), "Invalid verifier address");
        authorizedVerifiers[msg.sender].add(verifier);
        emit VerifierAuthorized(msg.sender, verifier);
    }
    
    function revokeVerifier(address verifier) external {
        require(authorizedVerifiers[msg.sender].contains(verifier), "Verifier not authorized");
        authorizedVerifiers[msg.sender].remove(verifier);
        emit VerifierRevoked(msg.sender, verifier);
    }
    
    function verifyResume(uint256 resumeId) external {
        require(authorizedVerifiers[resumes[resumeId].candidate].contains(msg.sender), "Not authorized to verify");
        resumes[resumeId].verified = true;
        emit ResumeVerified(resumeId, msg.sender);
    }
    
    function getResume(uint256 resumeId) external view returns (Resume memory) {
        require(resumes[resumeId].candidate == msg.sender || authorizedVerifiers[resumes[resumeId].candidate].contains(msg.sender), "Not authorized");
        return resumes[resumeId];
    }
}
