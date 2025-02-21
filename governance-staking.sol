// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract StakingGovernance is ReentrancyGuard, Ownable {
    IERC20 public immutable stakingToken;
    uint256 public totalStaked;
    uint256 public rewardPool;
    
    struct Stake {
        uint256 amount;
        uint256 timestamp;
        bool exists;
    }
    
    struct Proposal {
        string description;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 deadline;
        bool executed;
        mapping(address => bool) voted;
    }

    mapping(address => Stake) public stakes;
    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalCount;
    uint256 public constant LOCK_PERIOD = 7 days;
    uint256 public constant MIN_STAKE = 100 * 1e18;
    uint256 public constant PROPOSAL_DURATION = 3 days;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event ProposalCreated(uint256 indexed proposalId, string description);
    event Voted(address indexed voter, uint256 indexed proposalId, bool vote);
    event ProposalExecuted(uint256 indexed proposalId);

    constructor(IERC20 _stakingToken) {
        stakingToken = _stakingToken;
    }

    function stake(uint256 amount) external nonReentrant {
        require(amount >= MIN_STAKE, "Stake amount too low");
        require(stakingToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        
        stakes[msg.sender].amount += amount;
        stakes[msg.sender].timestamp = block.timestamp;
        stakes[msg.sender].exists = true;
        totalStaked += amount;

        emit Staked(msg.sender, amount);
    }

    function unstake(uint256 amount) external nonReentrant {
        Stake storage userStake = stakes[msg.sender];
        require(userStake.exists, "No stake found");
        require(block.timestamp >= userStake.timestamp + LOCK_PERIOD, "Stake is locked");
        require(userStake.amount >= amount, "Insufficient stake");
        
        userStake.amount -= amount;
        totalStaked -= amount;
        require(stakingToken.transfer(msg.sender, amount), "Transfer failed");
        
        if (userStake.amount == 0) {
            userStake.exists = false;
        }

        emit Unstaked(msg.sender, amount);
    }

    function createProposal(string memory description) external {
        require(stakes[msg.sender].exists, "Only stakers can propose");
        
        proposalCount++;
        Proposal storage newProposal = proposals[proposalCount];
        newProposal.description = description;
        newProposal.deadline = block.timestamp + PROPOSAL_DURATION;
        
        emit ProposalCreated(proposalCount, description);
    }

    function vote(uint256 proposalId, bool support) external {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp <= proposal.deadline, "Voting period over");
        require(stakes[msg.sender].exists, "Only stakers can vote");
        require(!proposal.voted[msg.sender], "Already voted");

        proposal.voted[msg.sender] = true;
        
        if (support) {
            proposal.yesVotes += stakes[msg.sender].amount;
        } else {
            proposal.noVotes += stakes[msg.sender].amount;
        }

        emit Voted(msg.sender, proposalId, support);
    }

    function executeProposal(uint256 proposalId) external onlyOwner {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp > proposal.deadline, "Voting still open");
        require(!proposal.executed, "Already executed");
        
        proposal.executed = true;
        
        emit ProposalExecuted(proposalId);
    }

    function depositRewards(uint256 amount) external onlyOwner {
        require(stakingToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        rewardPool += amount;
    }
}
