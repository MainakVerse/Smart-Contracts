// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract StoryNFT is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _nftIds;

    // Mapping of NFT IDs to their owners
    mapping(address => mapping(uint256 => bool)) public userNFTs;

    // Mapping of NFT IDs to their metadata
    mapping(uint256 => string) public nftMetadata;

    // Mapping of story chapters to their current state
    mapping(uint256 => StoryChapter) public storyChapters;

    // Mapping of NFT IDs to their voting power
    mapping(uint256 => uint256) public nftVotingPower;

    // Structure for a story chapter
    struct StoryChapter {
        uint256 id;
        string description;
        uint256[] choices;
        mapping(uint256 => uint256) choiceVotes;
        uint256 winningChoice;
    }

    constructor() ERC721("Story NFT", "SN") {}

    // Function to mint a new NFT
    function mintNFT(address recipient, string memory metadata, uint256 votingPower) public onlyOwner {
        _nftIds.increment();
        uint256 newNFTId = _nftIds.current();

        _mint(recipient, newNFTId);
        nftMetadata[newNFTId] = metadata;
        userNFTs[recipient][newNFTId] = true;
        nftVotingPower[newNFTId] = votingPower;

        _setTokenURI(newNFTId, metadata);
    }

    // Function to create a new story chapter
    function createStoryChapter(uint256 chapterId, string memory description, uint256[] memory choices) public onlyOwner {
        storyChapters[chapterId].id = chapterId;
        storyChapters[chapterId].description = description;
        storyChapters[chapterId].choices = choices;
    }

    // Function to vote on a story choice
    function voteOnChoice(uint256 chapterId, uint256 choiceId, uint256 nftId) public {
        require(userNFTs[msg.sender][nftId], "You do not own this NFT");
        require(storyChapters[chapterId].choices.length > 0, "Chapter does not exist or has no choices");

        storyChapters[chapterId].choiceVotes[choiceId] += nftVotingPower[nftId];
    }

    // Function to determine the winning choice for a chapter
    function determineWinningChoice(uint256 chapterId) public onlyOwner {
        uint256 maxVotes = 0;
        uint256 winningChoiceId = 0;

        for (uint256 choiceId = 0; choiceId < storyChapters[chapterId].choices.length; choiceId++) {
            if (storyChapters[chapterId].choiceVotes[choiceId] > maxVotes) {
                maxVotes = storyChapters[chapterId].choiceVotes[choiceId];
                winningChoiceId = choiceId;
            }
        }

        storyChapters[chapterId].winningChoice = winningChoiceId;
    }

    // Function to get the winning choice for a chapter
    function getWinningChoice(uint256 chapterId) public view returns (uint256) {
        return storyChapters[chapterId].winningChoice;
    }
}
