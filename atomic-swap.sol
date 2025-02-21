// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AtomicSwap {
    struct Swap {
        address sender;
        address receiver;
        address tokenA;
        address tokenB;
        uint256 amountA;
        uint256 amountB;
        bytes32 hashlock;
        uint256 timelock;
        bool completed;
    }

    mapping(bytes32 => Swap) public swaps;

    event SwapCreated(
        bytes32 indexed swapId,
        address indexed sender,
        address indexed receiver,
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 amountB,
        bytes32 hashlock,
        uint256 timelock
    );

    event SwapCompleted(bytes32 indexed swapId);
    event SwapRefunded(bytes32 indexed swapId);

    function createSwap(
        address _receiver,
        address _tokenA,
        address _tokenB,
        uint256 _amountA,
        uint256 _amountB,
        bytes32 _hashlock,
        uint256 _timelock
    ) external returns (bytes32 swapId) {
        require(_receiver != address(0), "Invalid receiver");
        require(_tokenA != address(0) && _tokenB != address(0), "Invalid token addresses");
        require(_amountA > 0 && _amountB > 0, "Invalid amounts");
        require(_timelock > block.timestamp, "Timelock must be in the future");

        swapId = keccak256(abi.encodePacked(msg.sender, _receiver, _tokenA, _tokenB, _amountA, _amountB, _hashlock, _timelock));
        require(swaps[swapId].sender == address(0), "Swap already exists");

        swaps[swapId] = Swap({
            sender: msg.sender,
            receiver: _receiver,
            tokenA: _tokenA,
            tokenB: _tokenB,
            amountA: _amountA,
            amountB: _amountB,
            hashlock: _hashlock,
            timelock: _timelock,
            completed: false
        });

        require(IERC20(_tokenA).transferFrom(msg.sender, address(this), _amountA), "Token A transfer failed");
        emit SwapCreated(swapId, msg.sender, _receiver, _tokenA, _tokenB, _amountA, _amountB, _hashlock, _timelock);
    }

    function completeSwap(bytes32 swapId, string memory secret) external {
        Swap storage swap = swaps[swapId];
        require(!swap.completed, "Swap already completed");
        require(msg.sender == swap.receiver, "Only receiver can complete swap");
        require(keccak256(abi.encodePacked(secret)) == swap.hashlock, "Invalid secret");

        swap.completed = true;
        require(IERC20(swap.tokenB).transferFrom(msg.sender, swap.sender, swap.amountB), "Token B transfer failed");
        require(IERC20(swap.tokenA).transfer(msg.sender, swap.amountA), "Token A transfer failed");

        emit SwapCompleted(swapId);
    }

    function refundSwap(bytes32 swapId) external {
        Swap storage swap = swaps[swapId];
        require(!swap.completed, "Swap already completed");
        require(block.timestamp >= swap.timelock, "Timelock not expired");
        require(msg.sender == swap.sender, "Only sender can refund");

        swap.completed = true;
        require(IERC20(swap.tokenA).transfer(swap.sender, swap.amountA), "Refund failed");

        emit SwapRefunded(swapId);
    }
}
