pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.8.0/contracts/token/ERC20/IERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.8.0/contracts/token/ERC20/utils/SafeERC20.sol";

contract DecentralizedBettingPlatform {
    using SafeERC20 for IERC20;

    // Mapping of users to their balances
    mapping(address => uint256) public userBalances;

    // Mapping of bets to their details
    mapping(bytes32 => Bet) public bets;

    // Mapping of events to their outcomes
    mapping(bytes32 => Outcome) public eventOutcomes;

    // Mapping of users to their bets
    mapping(address => bytes32[]) public userBets;

    // Supported token for betting
    IERC20 public token;

    // Event identifier
    bytes32 public eventID;

    // Bet struct
    struct Bet {
        address user;
        uint256 amount;
        bytes32 eventID;
        uint256 outcomeIndex; // Index of the chosen outcome
    }

    // Outcome struct
    struct Outcome {
        string description;
        uint256 odds;
        bool isWinner;
    }

    // Constructor
    constructor(address _tokenAddress) {
        token = IERC20(_tokenAddress);
    }

    // Function to place a bet
    function placeBet(bytes32 _eventID, uint256 _outcomeIndex, uint256 _amount) public {
        require(_amount > 0, "Bet amount must be greater than zero");
        require(userBalances[msg.sender] >= _amount, "Insufficient balance");

        // Deduct bet amount from user's balance
        userBalances[msg.sender] -= _amount;

        // Create a new bet
        bytes32 betID = keccak256(abi.encodePacked(msg.sender, _eventID, _outcomeIndex, block.timestamp));
        bets[betID] = Bet(msg.sender, _amount, _eventID, _outcomeIndex);

        // Add bet to user's bets
        userBets[msg.sender].push(betID);
    }

    // Function to settle an event
    function settleEvent(bytes32 _eventID, uint256 _winningOutcomeIndex) public {
        // Update the winning outcome
        eventOutcomes[_eventID].isWinner = true;
        eventOutcomes[_eventID].outcomeIndex = _winningOutcomeIndex;

        // Iterate through all bets for this event
        for (bytes32 betID in userBets[msg.sender]) {
            Bet storage bet = bets[betID];
            if (bet.eventID == _eventID) {
                // Check if the bet is a winner
                if (bet.outcomeIndex == _winningOutcomeIndex) {
                    // Calculate winnings
                    uint256 winnings = bet.amount * eventOutcomes[_eventID].odds;

                    // Add winnings to user's balance
                    userBalances[bet.user] += winnings;

                    // Transfer winnings to user
                    token.safeTransfer(bet.user, winnings);
                }
            }
        }
    }

    // Function to deposit funds
    function deposit(uint256 _amount) public {
        // Transfer tokens from user to contract
        token.safeTransferFrom(msg.sender, address(this), _amount);

        // Update user's balance
        userBalances[msg.sender] += _amount;
    }

    // Function to withdraw funds
    function withdraw(uint256 _amount) public {
        require(userBalances[msg.sender] >= _amount, "Insufficient balance");

        // Update user's balance
        userBalances[msg.sender] -= _amount;

        // Transfer tokens back to user
        token.safeTransfer(msg.sender, _amount);
    }
}

