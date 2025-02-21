// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract StakingContract is ReentrancyGuard {
    IERC20 public immutable stakingToken;
    IERC20 public immutable rewardToken;
    
    struct Stake {
        uint256 amount;
        uint256 timestamp;
        uint256 rewardDebt;
    }

    mapping(address => Stake) public stakes;
    uint256 public totalStaked;
    uint256 public rewardRatePerSecond = 1e18; // Example: 1 token per second
    
    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 reward);
    
    constructor(IERC20 _stakingToken, IERC20 _rewardToken) {
        stakingToken = _stakingToken;
        rewardToken = _rewardToken;
    }
    
    function stake(uint256 _amount) external nonReentrant {
        require(_amount > 0, "Cannot stake zero tokens");
        stakingToken.transferFrom(msg.sender, address(this), _amount);
        
        Stake storage userStake = stakes[msg.sender];
        
        if (userStake.amount > 0) {
            uint256 pendingRewards = _calculateRewards(msg.sender);
            userStake.rewardDebt += pendingRewards;
        }
        
        userStake.amount += _amount;
        userStake.timestamp = block.timestamp;
        totalStaked += _amount;
        
        emit Staked(msg.sender, _amount);
    }
    
    function unstake(uint256 _amount) external nonReentrant {
        Stake storage userStake = stakes[msg.sender];
        require(userStake.amount >= _amount, "Insufficient balance to unstake");
        
        uint256 pendingRewards = _calculateRewards(msg.sender);
        userStake.rewardDebt += pendingRewards;
        userStake.amount -= _amount;
        totalStaked -= _amount;
        
        stakingToken.transfer(msg.sender, _amount);
        emit Unstaked(msg.sender, _amount);
    }
    
    function claimRewards() external nonReentrant {
        uint256 rewards = _calculateRewards(msg.sender) + stakes[msg.sender].rewardDebt;
        require(rewards > 0, "No rewards to claim");
        
        stakes[msg.sender].rewardDebt = 0;
        stakes[msg.sender].timestamp = block.timestamp;
        
        rewardToken.transfer(msg.sender, rewards);
        emit RewardsClaimed(msg.sender, rewards);
    }
    
    function _calculateRewards(address _user) internal view returns (uint256) {
        Stake memory userStake = stakes[_user];
        uint256 duration = block.timestamp - userStake.timestamp;
        return (userStake.amount * rewardRatePerSecond * duration) / 1e18;
    }
}

