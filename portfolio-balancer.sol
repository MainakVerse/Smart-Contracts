// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract DeFiIndexFund is Ownable {
    struct TokenInfo {
        IERC20 token;
        AggregatorV3Interface priceFeed;
        uint256 targetWeight; // Weight in basis points (10000 = 100%)
    }
    
    IUniswapV2Router02 public dexRouter;
    TokenInfo[] public tokens;
    uint256 public rebalanceThreshold = 500; // 5% deviation allowed

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event Rebalanced();

    constructor(address _dexRouter) {
        dexRouter = IUniswapV2Router02(_dexRouter);
    }

    function addToken(address _token, address _priceFeed, uint256 _weight) external onlyOwner {
        tokens.push(TokenInfo({
            token: IERC20(_token),
            priceFeed: AggregatorV3Interface(_priceFeed),
            targetWeight: _weight
        }));
    }

    function deposit(uint256 amount) external {
        require(amount > 0, "Deposit amount must be greater than zero");
        // Deposit logic (users deposit ETH or stablecoin, distributed to tokens)
        emit Deposited(msg.sender, amount);
    }

    function withdraw(uint256 amount) external {
        require(amount > 0, "Withdraw amount must be greater than zero");
        // Withdraw logic
        emit Withdrawn(msg.sender, amount);
    }

    function getLatestPrice(AggregatorV3Interface priceFeed) internal view returns (uint256) {
        (, int256 price,,,) = priceFeed.latestRoundData();
        require(price > 0, "Invalid price feed data");
        return uint256(price);
    }

    function rebalance() external onlyOwner {
        // Fetch current values and rebalance tokens
        for (uint i = 0; i < tokens.length; i++) {
            uint256 currentPrice = getLatestPrice(tokens[i].priceFeed);
            // Check if rebalancing is needed based on threshold
            if (true) { // Placeholder for rebalance condition
                // Swap logic via Uniswap
            }
        }
        emit Rebalanced();
    }
}
