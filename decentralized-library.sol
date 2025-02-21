// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract DecentralizedLottery is VRFConsumerBase {
    address public owner;
    address payable[] public participants;
    uint256 public lotteryId;
    uint256 public ticketPrice;
    bool public lotteryOpen;
    bytes32 internal keyHash;
    uint256 internal fee;
    
    mapping(uint256 => address payable) public lotteryWinners;
    
    event LotteryStarted(uint256 lotteryId, uint256 ticketPrice);
    event LotteryEnded(uint256 lotteryId, address winner, uint256 prize);
    event TicketPurchased(address indexed participant, uint256 amount);
    event RandomnessRequested(bytes32 requestId);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }
    
    modifier lotteryActive() {
        require(lotteryOpen, "Lottery is not active");
        _;
    }
    
    constructor(address _vrfCoordinator, address _linkToken, bytes32 _keyHash, uint256 _fee) 
        VRFConsumerBase(_vrfCoordinator, _linkToken) 
    {
        owner = msg.sender;
        keyHash = _keyHash;
        fee = _fee;
        lotteryId = 1;
    }
    
    function startLottery(uint256 _ticketPrice) external onlyOwner {
        require(!lotteryOpen, "A lottery is already in progress");
        ticketPrice = _ticketPrice;
        lotteryOpen = true;
        delete participants;
        emit LotteryStarted(lotteryId, ticketPrice);
    }
    
    function enterLottery() external payable lotteryActive {
        require(msg.value == ticketPrice, "Incorrect ETH amount sent");
        participants.push(payable(msg.sender));
        emit TicketPurchased(msg.sender, msg.value);
    }
    
    function endLottery() external onlyOwner lotteryActive {
        require(participants.length > 0, "No participants in the lottery");
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK for randomness");
        
        bytes32 requestId = requestRandomness(keyHash, fee);
        emit RandomnessRequested(requestId);
        
        lotteryOpen = false;
    }
    
    function fulfillRandomness(bytes32, uint256 randomness) internal override {
        require(!lotteryOpen, "Lottery must be closed before drawing winner");
        require(participants.length > 0, "No participants available");
        
        uint256 winnerIndex = randomness % participants.length;
        address payable winner = participants[winnerIndex];
        uint256 prize = address(this).balance;
        
        lotteryWinners[lotteryId] = winner;
        lotteryId++;
        
        (bool success, ) = winner.call{value: prize}(" ");
        require(success, "Transfer to winner failed");
        
        emit LotteryEnded(lotteryId - 1, winner, prize);
    }
    
    function getParticipants() external view returns (address payable[] memory) {
        return participants;
    }
    
    function withdrawLINK() external onlyOwner {
        require(LINK.transfer(owner, LINK.balanceOf(address(this))), "LINK withdrawal failed");
    }
    
    receive() external payable {}
}
