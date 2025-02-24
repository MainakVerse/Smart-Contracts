pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.8.0/contracts/token/ERC721/ERC721.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.8.0/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.8.0/contracts/utils/Counters.sol";

contract VirtualRealEstateNFT is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // Mapping of virtual land NFTs to their details
    mapping(uint256 => VirtualLand) public virtualLands;

    // Mapping of users to their virtual land NFTs
    mapping(address => uint256[]) public userLands;

    // Virtual land struct
    struct VirtualLand {
        uint256 id;
        string name;
        string location;
        uint256 size;
        address owner;
    }

    // Constructor
    constructor() ERC721("VirtualRealEstate", "VRE") {}

    // Function to create a new virtual land NFT
    function createVirtualLand(address _owner, string memory _name, string memory _location, uint256 _size) public {
        _tokenIds.increment();
        uint256 newLandId = _tokenIds.current();

        // Mint a new NFT
        _mint(_owner, newLandId);

        // Set NFT URI
        _setTokenURI(newLandId, "https://example.com/land-metadata");

        // Create a new virtual land
        virtualLands[newLandId] = VirtualLand(newLandId, _name, _location, _size, _owner);

        // Add land to user's lands
        userLands[_owner].push(newLandId);
    }

    // Function to buy a virtual land NFT
    function buyVirtualLand(uint256 _landId) public {
        require(virtualLands[_landId].owner != msg.sender, "You already own this land");
        require(virtualLands[_landId].owner != address(0), "Land does not exist");

        // Transfer ownership of the land
        _transfer(virtualLands[_landId].owner, msg.sender, _landId);

        // Update land details
        virtualLands[_landId].owner = msg.sender;

        // Add land to buyer's lands
        userLands[msg.sender].push(_landId);
    }

    // Function to develop virtual land
    function developVirtualLand(uint256 _landId, string memory _developmentType) public {
        require(virtualLands[_landId].owner == msg.sender, "You do not own this land");

        // Update land metadata to reflect development
        _setTokenURI(_landId, "https://example.com/updated-land-metadata");

        // Add development details to land struct
        // For simplicity, assume we have a function `addDevelopmentDetails` that updates the land struct
        addDevelopmentDetails(_landId, _developmentType);
    }
}
