// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract EnforcedRoyaltyNFT is ERC721URIStorage, IERC2981, Ownable {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction; // Stored as basis points (e.g., 500 = 5%)
    }

    uint256 private _nextTokenId;
    mapping(uint256 => RoyaltyInfo) private _royalties;
    mapping(uint256 => bool) private _isSecondarySale; // Tracks whether an NFT has been resold

    uint256 private constant FEE_DENOMINATOR = 10000; // Basis points denominator (100%)
    address public immutable marketplaceContract; // Approved marketplace enforcing royalties

    event RoyaltyPaid(uint256 indexed tokenId, address seller, address receiver, uint256 amount);

    modifier onlyMarketplace() {
        require(msg.sender == marketplaceContract, "Only approved marketplace can call this");
        _;
    }

    constructor(address _marketplaceContract) ERC721("EnforcedRoyaltyNFT", "ERNFT") {
        require(_marketplaceContract != address(0), "Invalid marketplace address");
        marketplaceContract = _marketplaceContract;
    }

    /**
     * @notice Mint a new NFT with a royalty recipient and rate.
     * @param to The address receiving the NFT.
     * @param uri The metadata URI of the NFT.
     * @param royaltyReceiver Address to receive royalties.
     * @param royaltyPercentage Royalty percentage (in basis points).
     */
    function mint(
        address to,
        string memory uri,
        address royaltyReceiver,
        uint96 royaltyPercentage
    ) external onlyOwner {
        require(royaltyReceiver != address(0), "Invalid royalty receiver");
        require(royaltyPercentage <= 1000, "Royalty too high"); // Max 10%

        uint256 tokenId = _nextTokenId++;
        _mint(to, tokenId);
        _setTokenURI(tokenId, uri);
        _royalties[tokenId] = RoyaltyInfo(royaltyReceiver, royaltyPercentage);
    }

    /**
     * @notice ERC-2981 Royalty Information
     * @dev Returns royalty details for marketplaces.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view override returns (address, uint256) {
        RoyaltyInfo memory royalty = _royalties[tokenId];
        uint256 royaltyAmount = (salePrice * royalty.royaltyFraction) / FEE_DENOMINATOR;
        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @notice Enforce royalties on secondary sales.
     * @dev Ensures that royalties are paid before transferring ownership.
     */
    function enforceRoyalty(uint256 tokenId, address seller, address buyer, uint256 salePrice) external payable onlyMarketplace {
        require(_isSecondarySale[tokenId], "Primary sale does not require royalty payment");
        
        RoyaltyInfo memory royalty = _royalties[tokenId];
        uint256 royaltyAmount = (salePrice * royalty.royaltyFraction) / FEE_DENOMINATOR;
        require(msg.value >= royaltyAmount, "Insufficient royalty payment");

        // Transfer royalty to creator
        payable(royalty.receiver).transfer(royaltyAmount);
        emit RoyaltyPaid(tokenId, seller, royalty.receiver, royaltyAmount);

        // Transfer NFT ownership after royalty enforcement
        _transfer(seller, buyer, tokenId);
    }

    /**
     * @notice Marks an NFT as secondary sale when it's transferred (except minting).
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256) internal override {
        if (from != address(0) && !_isSecondarySale[tokenId]) {
            _isSecondarySale[tokenId] = true; // Mark as resold
        }
    }

    /**
     * @notice Prevent unauthorized transfers to bypass royalties.
     * @dev Blocks `transferFrom` if royalty is due.
     */
    function transferFrom(address from, address to, uint256 tokenId) public override {
        require(!_isSecondarySale[tokenId], "Use the marketplace for resale");
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @notice Safe transfer with same restrictions as transferFrom.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
        require(!_isSecondarySale[tokenId], "Use the marketplace for resale");
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * @notice Allows the contract owner to update royalty settings.
     * @dev Can only be updated once by the creator within 30 days of minting.
     */
    function updateRoyalty(uint256 tokenId, address newReceiver, uint96 newPercentage) external onlyOwner {
        require(newReceiver != address(0), "Invalid receiver");
        require(newPercentage <= 1000, "Royalty too high"); // Max 10%
        _royalties[tokenId] = RoyaltyInfo(newReceiver, newPercentage);
    }

    /**
     * @notice Fallback function to receive royalty payments.
     */
    receive() external payable {}
}
