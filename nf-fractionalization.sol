// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FractionalizedNFT is ERC20, Ownable {
    address public nftContract;
    uint256 public tokenId;
    uint256 public buyoutPrice;
    bool public isBuyoutActive;

    constructor(
        address _nftContract,
        uint256 _tokenId,
        uint256 _totalSupply,
        uint256 _buyoutPrice
    ) ERC20("Fractional NFT Token", "F-NFT") {
        nftContract = _nftContract;
        tokenId = _tokenId;
        buyoutPrice = _buyoutPrice;
        isBuyoutActive = false;

        // Mint fractional tokens to the contract owner
        _mint(msg.sender, _totalSupply);

        // Transfer NFT to this contract
        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);
    }

    function initiateBuyout() external payable {
        require(!isBuyoutActive, "Buyout already in progress");
        require(msg.value >= buyoutPrice, "Insufficient buyout amount");

        isBuyoutActive = true;
    }

    function redeemNFT() external {
        require(isBuyoutActive, "Buyout not initiated");
        require(balanceOf(msg.sender) == totalSupply(), "Must own all fractions");

        IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
        isBuyoutActive = false;
    }

    function withdrawFunds() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
