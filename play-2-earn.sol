// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PlayToEarnRewards is Ownable {
    IERC20 public rewardToken;

    struct Achievement {
        string name;
        uint256 rewardAmount;
        bool exists;
    }

    mapping(address => mapping(uint256 => bool)) public hasClaimed;
    mapping(uint256 => Achievement) public achievements;
    uint256 public totalAchievements;

    event AchievementAdded(uint256 indexed id, string name, uint256 rewardAmount);
    event RewardClaimed(address indexed player, uint256 indexed achievementId, uint256 amount);

    constructor(address _rewardToken) {
        rewardToken = IERC20(_rewardToken);
    }

    function addAchievement(string memory _name, uint256 _rewardAmount) external onlyOwner {
        require(_rewardAmount > 0, "Reward must be greater than zero");

        totalAchievements++;
        achievements[totalAchievements] = Achievement({
            name: _name,
            rewardAmount: _rewardAmount,
            exists: true
        });

        emit AchievementAdded(totalAchievements, _name, _rewardAmount);
    }

    function claimReward(uint256 _achievementId) external {
        require(achievements[_achievementId].exists, "Achievement does not exist");
        require(!hasClaimed[msg.sender][_achievementId], "Reward already claimed");

        hasClaimed[msg.sender][_achievementId] = true;
        uint256 rewardAmount = achievements[_achievementId].rewardAmount;
        require(rewardToken.transfer(msg.sender, rewardAmount), "Transfer failed");

        emit RewardClaimed(msg.sender, _achievementId, rewardAmount);
    }
}
