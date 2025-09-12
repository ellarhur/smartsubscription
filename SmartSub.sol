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
    uint256 public nextSubscriptionId; // Makes an ID available for the next created subscription
    uint256 public nextSubscriberId; // Makes an ID available for the next created subscriber

// Mappings
    mapping(uint256 => Subscription) public subscriptions;
    mapping(address => uint256[]) public subscribers;
    mapping(string => uint256) public titleToSubscriptionId; // Mapping från titel till ID
 

// Events
    event SubCreated(uint256 indexed subscriptionId, address indexed ownerAddress, string title, uint256 fee, uint256 cycleLength);
    event SubUpdated(uint256 indexed subscriptionId, uint256 newFee);
    event SubStatusChanged(uint256 indexed subscriptionId, SubscriptionStatus status);
    event SubTransferred(uint256 indexed subscriptionId, address indexed from, address indexed to);
    event RevenueWithdrawn(uint256 indexed subscriptionId, address indexed ownerAddress, uint256 amount);

// Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can do this.");
        _;
    }
    
    modifier onlySubOwner(uint256 subscriptionId) {
        require(subscriptions[subscriptionId].ownerAddress == msg.sender, "Only the subscription owner can do this.");
        _;
    }
    
    modifier subExists(uint256 subscriptionId) {
        require(subscriptionId < nextSubscriptionId, "This subscription does not exist.");
        _;
    }
    
    modifier subActive(uint256 subscriptionId) {
        require(subscriptions[subscriptionId].status == SubscriptionStatus.Active, "This subscription is paused.");
        _;
    }
    
    modifier validPeriod(uint256 cycleLength) {
        require(cycleLength >= 1 days, "You have to set a cycle length for your subscription.");
        _;
    }

// Constructor
    constructor() {
    owner = msg.sender;
    nextSubscriberId = 0;
    nextSubscriptionId = 0;
    }


    function createSub(string memory title, uint256 fee, uint256 cycleLength) public returns(uint256) {
        require(bytes(title).length > 0, "You have to give the service subscription a name or title.");
        require(titleToSubscriptionId[title] == 0, "A subscription with this title already exists.");

        uint256 subscriptionId = nextSubscriptionId++;
           subscriptions[subscriptionId] = Subscription({
            subscriptionId: subscriptionId,
            title: title,
            ownerAddress: msg.sender,
            fee: fee,
            cycleLength: cycleLength,
            status: SubscriptionStatus.Active,
            paused: false
        });

        titleToSubscriptionId[title] = subscriptionId; // Spara titel-till-ID mapping
        subscribers[msg.sender].push(subscriptionId);
        emit SubCreated(subscriptionId, msg.sender, title, fee, cycleLength);
        return subscriptionId;
    }

    // Prenumerera med titel istället för ID - mycket mer användarvänligt!
    function subscribeByTitle(string memory title) external payable {
        uint256 subscriptionId = titleToSubscriptionId[title];
        require(subscriptionId != 0, "No subscription found with this title.");
        require(subscriptions[subscriptionId].status == SubscriptionStatus.Active, "This subscription is not active.");
        
        Subscription storage subscription = subscriptions[subscriptionId];
        require(msg.value >= subscription.fee, "You don't have enough ETH to subscribe unfortunately.");
        
        // Transfer payment to subscription owner
        payable(subscription.ownerAddress).transfer(msg.value);
    }

    // Behåll den gamla funktionen för bakåtkompatibilitet
    function subscribe(uint256 subscriptionId) external 
        payable 
        subExists(subscriptionId) 
        subActive(subscriptionId)  {
        Subscription storage subscription = subscriptions[subscriptionId];
        require(msg.value >= subscription.fee, "You don't have enough ETH to subscribe unfortunately.");
        
        // Transfer payment to subscription owner
        payable(subscription.ownerAddress).transfer(msg.value);
    }

}