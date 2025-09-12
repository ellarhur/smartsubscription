// The Smart Contact for my subscription service
// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

contract SmartSub {
      address public owner;
    
// Struct & Enums
    enum SubscriptionStatus { Active, Paused }
    struct Subscription {
        uint256 subscriptionId;
        string title;
        address ownerAddress;
        uint256 fee;
        uint256 cycleLength;
        SubscriptionStatus status;
        bool paused;
    }
    struct Subscriber {
        uint256 subscriberId;
        address subscriberAddress;
        uint256 balance;
    }

// State variables
    address public ownerAddress; // Saves the owner address on the blockchain
    uint256 public nextSubscriptionId; // Makes an ID available for the next created subscription
    uint256 public nextSubscriberId; // Makes an ID available for the next created subscriber

// Mappings
    mapping(uint256 => Subscription) public subscriptions;
    mapping(address => uint256[]) public subscribers;
    mapping(uint256 => uint256[]) public subscriptionSubscriptions;
 

// Events
    event SubCreated(uint256 indexed serviceId, address indexed owner, string name, uint256 fee, uint256 periodLength);
    event SubUpdated(uint256 indexed serviceId, uint256 newFee);
    event SubStatusChanged(uint256 indexed serviceId, ServiceStatus status);
    event SubTransferred(uint256 indexed subscriptionId, address indexed from, address indexed to);
    event RevenueWithdrawn(uint256 indexed serviceId, address indexed owner, uint256 amount);

// Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can do this.");
        _;
    }
    
    modifier onlySubOwner(uint256 serviceId) {
        require(services[serviceId].owner == msg.sender, "Only the contract owner can do this.");
        _;
    }
    
    modifier subExists(uint256 serviceId) {
        require(serviceId < nextServiceId, "This subscription does not exist.");
        _;
    }
    
    modifier serviceActive(uint256 serviceId) {
        require(services[serviceId].status == ServiceStatus.Active, "This subscription is paused.");
        _;
    }
    
    modifier validPeriod(uint256 cycleLength) {
        require(periodLength >= 1 days, "You have to set a cycle length for your subscription.");
        _;
    }

// Constructor
    constructor() {
    owner = msg.sender;
    nextSubscriberId = 0;
    nextSubscriptionId = 0;
    }


    function createSub(string memory title, uint256 fee, uint256 cycleLength, subStatus status) public {
        require(bytes(name).length > 0, "You have to give the service subscription a name or title.");

        uint256 subscriptionId = nextSubscriptionId++;
           subscriptions[subscriptionId] = Subscription({
            owner: msg.sender,
            fee: fee,
            cycleLength: cycleLength,
            status: SubscriptionStatus.Active,
            totalRevenue: 0,
            name: name
        });

        subscribers[msg.sender].push(subscriptionId);
        emit SubCreated(subscriptionId, msg.sender, title, fee, cycleLength);
        return subscriptionId;
    }

    function subscribe(uint256 subscriptionId) external 
        payable 
        subExists(subscriptionId) 
        subActive(subscriptionId)  {
        Subscription storage subscription = subscriptions[subscriptionId];
        require(msg.value >= service.fee, "You don't have enough ETH to subscribe unfortunatly.");
        
        // Check if subscriber already hav an active subscription
        uint256 existingSubId = subscriberSubscriptions[msg.sender][subscriptionId];
        if (existingSubId > 0 && subscriptions[existingSubId].isActive) {
            // Message that they already have an active subscription
            revert("You already are subscribed to this subscription!")
        } else {
            // Otherwise create the new subscription
            createNewSubscription(subscriptionId, msg.sender);
        }
 
    }

}