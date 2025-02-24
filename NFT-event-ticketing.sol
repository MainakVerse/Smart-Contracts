pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.8.0/contracts/token/ERC721/ERC721.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.8.0/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.8.0/contracts/utils/Counters.sol";

contract NFTEventTickets is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // Mapping of NFT tickets to their details
    mapping(uint256 => Ticket) public tickets;

    // Mapping of users to their NFT tickets
    mapping(address => uint256[]) public userTickets;

    // Event details
    string public eventName;
    uint256 public eventDate;

    // Ticket struct
    struct Ticket {
        uint256 id;
        address owner;
        uint256 price;
        bool isResold;
    }

    // Constructor
    constructor(string memory _eventName, uint256 _eventDate) ERC721("EventTickets", "ETK") {
        eventName = _eventName;
        eventDate = _eventDate;
    }

    // Function to create a new NFT ticket
    function createTicket(address _owner, uint256 _price) public {
        _tokenIds.increment();
        uint256 newTicketId = _tokenIds.current();

        // Mint a new NFT ticket
        _mint(_owner, newTicketId);

        // Set NFT ticket URI
        _setTokenURI(newTicketId, "https://example.com/ticket-metadata");

        // Create a new ticket
        tickets[newTicketId] = Ticket(newTicketId, _owner, _price, false);

        // Add ticket to user's tickets
        userTickets[_owner].push(newTicketId);
    }

    // Function to buy an NFT ticket
    function buyTicket(uint256 _ticketId) public {
        require(tickets[_ticketId].owner != msg.sender, "You already own this ticket");
        require(tickets[_ticketId].isResold == false, "Ticket has been resold");

        // Transfer ownership of the ticket
        _transfer(tickets[_ticketId].owner, msg.sender, _ticketId);

        // Update ticket details
        tickets[_ticketId].owner = msg.sender;

        // Add ticket to buyer's tickets
        userTickets[msg.sender].push(_ticketId);
    }

    // Function to resell an NFT ticket
    function resellTicket(uint256 _ticketId, uint256 _newPrice) public {
        require(tickets[_ticketId].owner == msg.sender, "You do not own this ticket");
        require(tickets[_ticketId].isResold == false, "Ticket has already been resold");

        // Update ticket price
        tickets[_ticketId].price = _newPrice;

        // Mark ticket as resold
        tickets[_ticketId].isResold = true;
    }

    // Function to prevent scalping by limiting resales
    function limitResales(uint256 _maxResales) public {
        // Implement logic to limit the number of resales per ticket
        // For simplicity, assume we have a function `checkResaleLimit` that checks if a ticket has reached its resale limit
        require(checkResaleLimit(_ticketId, _maxResales) == false, "Ticket resale limit reached");
    }

    // Function to verify ticket ownership
    function verifyTicketOwnership(uint256 _ticketId) public view returns (bool) {
        return tickets[_ticketId].owner == msg.sender;
    }
}
