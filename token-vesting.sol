// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenVesting is Ownable {
    IERC20 public immutable token;  // Token to be vested

    struct VestingSchedule {
        uint256 start;
        uint256 cliff;
        uint256 duration;
        uint256 totalAmount;
        uint256 released;
        bool revocable;
        bool revoked;
    }

    mapping(address => VestingSchedule) public vestings;

    event TokensReleased(address beneficiary, uint256 amount);
    event VestingRevoked(address beneficiary);

    constructor(address _token) {
        require(_token != address(0), "Invalid token address");
        token = IERC20(_token);
    }

    function addBeneficiary(
        address _beneficiary,
        uint256 _start,
        uint256 _cliffDuration,
        uint256 _duration,
        uint256 _amount,
        bool _revocable
    ) external onlyOwner {
        require(_beneficiary != address(0), "Invalid beneficiary address");
        require(vestings[_beneficiary].totalAmount == 0, "Vesting already exists");
        require(_amount > 0, "Amount must be greater than 0");
        require(_duration > 0, "Duration must be greater than 0");

        uint256 cliff = _start + _cliffDuration;
        vestings[_beneficiary] = VestingSchedule({
            start: _start,
            cliff: cliff,
            duration: _duration,
            totalAmount: _amount,
            released: 0,
            revocable: _revocable,
            revoked: false
        });

        require(token.transferFrom(msg.sender, address(this), _amount), "Token transfer failed");
    }

    function releaseTokens() external {
        VestingSchedule storage vesting = vestings[msg.sender];
        require(vesting.totalAmount > 0, "No vesting schedule");
        require(block.timestamp >= vesting.cliff, "
