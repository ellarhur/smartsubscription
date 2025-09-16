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
    }

// State variables
    uint256 public nextSubscriptionId; // Makes an ID available for the next created subscription
    uint256 public nextSubscriberId; // Makes an ID available for the next created subscriber

// Mappings
    mapping(uint256 => Subscription) public subscriptions;
    mapping(address => uint256[]) public subscribers;
    mapping(string => uint256) public titleToSubscriptionId; // Mapping från titel till ID
    mapping(address => mapping(uint256 => bool)) public userSubscriptions; // Spåra vilka användare som prenumererar på vad
    mapping(address => mapping(uint256 => uint256)) public userSubscriptionStart; // När prenumerationen startade
 

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


 // -- FUNCTIONS FOR OWNERS -- //  

// Function for owners to create a new subscription service
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

// Function for owners to manage their subscription service's fee
    function manageSub(uint256 subscriptionId, uint256 newFee, SubscriptionStatus newStatus) public onlySubOwner(subscriptionId) {
        require(subscriptionId < nextSubscriptionId, "This subscription does not exist.");
        
        Subscription storage subscription = subscriptions[subscriptionId];
        subscription.fee = newFee;
        subscription.status = newStatus;
        
        emit SubUpdated(subscriptionId, newFee);
        emit SubStatusChanged(subscriptionId, newStatus);
    }

// Function for owners to withdraw the revenue
function withdrawRevenue(uint256 subscriptionId) external onlySubOwner(subscriptionId) {
    require(subscriptionId < nextSubscriptionId, "This subscription does not exist.");
}


 // -- FUNCTIONS FOR SUBSCRIBERS -- //  

// Function for subscribers to start subscribing by ID
    function subscribe(uint256 subscriptionId) external 
        payable 
        subExists(subscriptionId) 
        subActive(subscriptionId)  {
        Subscription storage subscription = subscriptions[subscriptionId];
        require(msg.value >= subscription.fee, "You don't have enough ETH to subscribe unfortunately.");
        require(!userSubscriptions[msg.sender][subscriptionId], "You are already subscribed to this service.");
        
        userSubscriptions[msg.sender][subscriptionId] = true; // Markera användaren som prenumerant
        userSubscriptionStart[msg.sender][subscriptionId] = block.timestamp; // Spara starttid
        payable(subscription.ownerAddress).transfer(msg.value);
    }
    
// Function for subscribers to start subscribing by title
    function subscribeByTitle(string memory title) external payable {
        uint256 subscriptionId = titleToSubscriptionId[title];
        require(subscriptionId != 0, "No subscription found with this title.");
        require(subscriptions[subscriptionId].status == SubscriptionStatus.Active, "This subscription is not active.");
        require(!userSubscriptions[msg.sender][subscriptionId], "You are already subscribed to this service.");
        
        Subscription storage subscription = subscriptions[subscriptionId];
        require(msg.value >= subscription.fee, "You don't have enough ETH to subscribe unfortunately.");
        
        userSubscriptions[msg.sender][subscriptionId] = true; // Markera användaren som prenumerant
        userSubscriptionStart[msg.sender][subscriptionId] = block.timestamp; // Spara starttid
        payable(subscription.ownerAddress).transfer(msg.value);
    }

// Function for subscribers to be able to pause their subscription by the ID
    function pauseSub(uint256 subscriptionId) public {
        require(subscriptionId < nextSubscriptionId, "This subscription does not exist.");
        require(userSubscriptions[msg.sender][subscriptionId], "You are not subscribed to this service.");
        
        userSubscriptions[msg.sender][subscriptionId] = false; // Ta bort prenumerationen
    }

// Function for subscribers to be able to pause their subscription by putting in the title
    function pauseSubByTitle(string memory title) public {
        uint256 subscriptionId = titleToSubscriptionId[title];
        require(subscriptionId != 0, "No subscription found with this title.");
        require(userSubscriptions[msg.sender][subscriptionId], "You are not subscribed to this service.");
        
        userSubscriptions[msg.sender][subscriptionId] = false; // Ta bort prenumerationen
    }

// Function for subscribers to be able to give away their subscription 
function giveawaySub(uint256 subscriptionId, address to) public {
    require(subscriptionId < nextSubscriptionId, "This subscription doesn't exist.");
    require(userSubscriptions[msg.sender][subscriptionId], "You are not subscribed to this service.");
    
    userSubscriptions[msg.sender][subscriptionId] = false;
    userSubscriptions[to][subscriptionId] = true;
    userSubscriptionStart[to][subscriptionId] = userSubscriptionStart[msg.sender][subscriptionId]; // Behåll ursprunglig starttid
}

// Function for subscribers to check if they have an active subscription
function hasActiveSubscription(uint256 subscriptionId) public view returns (bool) {
    return userSubscriptions[msg.sender][subscriptionId];
}

// Function for subscribers to check if they have an active subscription by title
function hasActiveSubscriptionByTitle(string memory title) public view returns (bool) {
    uint256 subscriptionId = titleToSubscriptionId[title];
    require(subscriptionId != 0, "No subscription found with this title.");
    return userSubscriptions[msg.sender][subscriptionId];
}

// Function for subscribers to get their subscription end date
function getSubscriptionEndDate(uint256 subscriptionId) public view returns (uint256) {
    require(userSubscriptions[msg.sender][subscriptionId], "You are not subscribed to this service.");
    uint256 startTime = userSubscriptionStart[msg.sender][subscriptionId];
    uint256 cycleLength = subscriptions[subscriptionId].cycleLength;
    return startTime + cycleLength;
}

// Function for subscribers to get their subscription end date by title
function getSubscriptionEndDateByTitle(string memory title) public view returns (uint256) {
    uint256 subscriptionId = titleToSubscriptionId[title];
    require(subscriptionId != 0, "No subscription found with this title.");
    require(userSubscriptions[msg.sender][subscriptionId], "You are not subscribed to this service.");
    uint256 startTime = userSubscriptionStart[msg.sender][subscriptionId];
    uint256 cycleLength = subscriptions[subscriptionId].cycleLength;
    return startTime + cycleLength;
}

}