// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract QuadraticVoting is Ownable, ReentrancyGuard {
    struct Proposal {
        string description;
        uint256 totalVotes;
        bool finalized;
        mapping(address => uint256) votes;
    }

    uint256 public proposalCount;
    mapping(uint256 => Proposal) public proposals;
    mapping(address => uint256) public credits;

    event ProposalCreated(uint256 indexed proposalId, string description);
    event VoteCast(address indexed voter, uint256 indexed proposalId, uint256 votesSpent);
    event ProposalFinalized(uint256 indexed proposalId);

    function createProposal(string memory description) external onlyOwner {
        proposalCount++;
        Proposal storage newProposal = proposals[proposalCount];
        newProposal.description = description;
        emit ProposalCreated(proposalCount, description);
    }

    function allocateCredits(address voter, uint256 amount) external onlyOwner {
        credits[voter] += amount;
    }

    function vote(uint256 proposalId, uint256 votes) external nonReentrant {
        require(proposalId > 0 && proposalId <= proposalCount, "Invalid proposal");
        require(!proposals[proposalId].finalized, "Proposal finalized");
        require(credits[msg.sender] >= votes ** 2, "Insufficient credits");

        credits[msg.sender] -= votes ** 2;
        proposals[proposalId].votes[msg.sender] += votes;
        proposals[proposalId].totalVotes += votes;

        emit VoteCast(msg.sender, proposalId, votes);
    }

    function finalizeProposal(uint256 proposalId) external onlyOwner {
        require(proposalId > 0 && proposalId <= proposalCount, "Invalid proposal");
        Proposal storage proposal = proposals[proposalId];
        require(!proposal.finalized, "Already finalized");
        
        proposal.finalized = true;
        emit ProposalFinalized(proposalId);
    }
}
