pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.8.0/contracts/token/ERC20/IERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.8.0/contracts/token/ERC20/utils/SafeERC20.sol";

contract GameSubscriptionModel {
    using SafeERC20 for IERC20;

    // Mapping of subscribers to their subscription details
    mapping(address => Subscription) public subscribers;

    // Mapping of subscription plans to their details
    mapping(bytes32 => Plan) public plans;

    // Supported token for subscription payments
    IERC20 public token;

    // Event identifier
    bytes32 public eventID;

    // Subscription struct
    struct Subscription {
        address user;
        bytes32 planID;
        uint256 nextPaymentDate;
        bool isActive;
    }

    // Plan struct
    struct Plan {
        bytes32 id;
        uint256 monthlyFee;
        uint256 billingInterval; // In days
    }

    // Constructor
    constructor(address _tokenAddress) {
        token = IERC20(_tokenAddress);
    }

    // Function to subscribe to a plan
    function subscribe(bytes32 _planID) public {
        require(plans[_planID].monthlyFee > 0, "Plan does not exist or has no fee");

        // Check if user already has an active subscription
        require(subscribers[msg.sender].isActive == false, "User already has an active subscription");

        // Create a new subscription
        subscribers[msg.sender] = Subscription(msg.sender, _planID, block.timestamp + plans[_planID].billingInterval * 1 days, true);

        // Deduct initial payment from user's balance
        token.safeTransferFrom(msg.sender, address(this), plans[_planID].monthlyFee);
    }

    // Function to automate monthly payments
    function automatePayment(address _user) public {
        require(subscribers[_user].isActive == true, "User does not have an active subscription");

        // Check if payment is due
        require(block.timestamp >= subscribers[_user].nextPaymentDate, "Payment is not due yet");

        // Deduct monthly fee from user's balance
        token.safeTransferFrom(_user, address(this), plans[subscribers[_user].planID].monthlyFee);

        // Update next payment date
        subscribers[_user].nextPaymentDate += plans[subscribers[_user].planID].billingInterval * 1 days;
    }

    // Function to cancel a subscription
    function cancelSubscription() public {
        require(subscribers[msg.sender].isActive == true, "User does not have an active subscription");

        // Set subscription to inactive
        subscribers[msg.sender].isActive = false;
    }

    // Function to add a new plan
    function addPlan(bytes32 _planID, uint256 _monthlyFee, uint256 _billingInterval) public {
        plans[_planID] = Plan(_planID, _monthlyFee, _billingInterval);
    }
}
