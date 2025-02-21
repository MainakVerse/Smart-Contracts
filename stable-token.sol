// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract StableToken is ERC20, Ownable {
    AggregatorV3Interface internal priceFeed;
    uint256 public constant TARGET_PRICE = 1e18; // 1 token = $1 (scaled to 18 decimals)
    uint256 public lastPrice;

    event TokensMinted(address indexed to, uint256 amount);
    event TokensBurned(address indexed from, uint256 amount);
    event PriceUpdated(uint256 newPrice);

    constructor(address _priceFeed) ERC20("StableToken", "STBL") {
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    function getLatestPrice() public view returns (uint256) {
        (, int price,,,) = priceFeed.latestRoundData();
        require(price > 0, "Invalid price");
        return uint256(price) * 1e10; // Convert to 18 decimals
    }

    function adjustSupply() external onlyOwner {
        uint256 currentPrice = getLatestPrice();
        lastPrice = currentPrice;
        emit PriceUpdated(currentPrice);

        if (currentPrice > TARGET_PRICE) {
            uint256 excessSupply = (currentPrice - TARGET_PRICE) * totalSupply() / TARGET_PRICE;
            _burn(owner(), excessSupply);
            emit TokensBurned(owner(), excessSupply);
        } else if (currentPrice < TARGET_PRICE) {
            uint256 neededSupply = (TARGET_PRICE - currentPrice) * totalSupply() / TARGET_PRICE;
            _mint(owner(), neededSupply);
            emit TokensMinted(owner(), neededSupply);
        }
    }
}
