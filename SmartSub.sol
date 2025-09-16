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
        uint256 endDate;
        uint256 startDate;
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
    mapping(address => mapping(uint256 => bool)) public userSubscriptions; // Spåra vilka användare som prenumererar på vad
    mapping(address => mapping(uint256 => uint256)) public userSubscriptionStart; // När prenumerationen startade
 

// Events
    event SubCreated(uint256 indexed subscriptionId, address indexed ownerAddress, string title, uint256 fee, uint256 cycleLength, uint256 endDate, uint256 startDate);
    event SubUpdated(uint256 indexed subscriptionId, uint256 newFee);
    event SubStatusChanged(uint256 indexed subscriptionId, SubscriptionStatus status);
    event SubTransferred(uint256 indexed subscriptionId, address indexed from, address indexed to);
    event RevenueWithdrawn(uint256 indexed subscriptionId, address indexed ownerAddress, uint256 amount);
    event FallbackCalled(address indexed subscriberAddress);
    event OwnerSet(address indexed ownerAddress, string message);

// Custom Errors
error OnlySubOwnerError(address caller, address actualOwner);
error SubNotExistsError(uint256 subscriptionId);
error SubIsPausedError(uint256 subscriptionId);
error InvalidCycleLengthError(uint256 providedLength);
error NotEnoughETHError(uint256 provided, uint256 required);
error AlreadySubscribedError(address subscriber, uint256 subscriptionId);
error NotSubscribedError(address subscriber, uint256 subscriptionId);


// Constructor
    constructor() {
    owner = msg.sender;
    emit OwnerSet(msg.sender, "The owner has been set, it's you!");
    nextSubscriberId = 0;
    nextSubscriptionId = 0;
    }

// Modifiers
    
    modifier onlySubOwner(uint256 subscriptionId) {
        if (subscriptions[subscriptionId].ownerAddress != msg.sender) {
            revert OnlySubOwnerError(msg.sender, subscriptions[subscriptionId].ownerAddress);
        }
        _;
    }

    modifier subExists(uint256 subscriptionId) {
        if (subscriptionId >= nextSubscriptionId) {
            revert SubNotExistsError(subscriptionId);
        }
        _;
    }
    
    modifier subActive(uint256 subscriptionId) {
        if (subscriptions[subscriptionId].status != SubscriptionStatus.Active) {
            revert SubIsPausedError(subscriptionId);
        }
        _;
    }
    
    modifier validPeriod(uint256 cycleLength) {
        if (cycleLength < 1 days) {
            revert InvalidCycleLengthError(cycleLength);
        }
        _;
    }

// --- RECEIVE & FALLBACK --- //

// Fallback if a function is called that doesn't exist
fallback() external {
    emit FallbackCalled(msg.sender);
    revert("The function you called does not exist, try another one.");
}

// receive() returns ETH if money is sent to a function that doesn't exist
receive() external payable { 
    // Returnera pengarna omedelbart till avsändaren
    payable(msg.sender).transfer(msg.value);
    revert("This function does not exist, ETH is returned to you.");
}

 // -- FUNCTIONS FOR OWNERS -- //  

// Function for owners to create a new subscription service
    function createSub(string memory title, uint256 fee, uint256 cycleLength, uint256 endDate, uint256 startDate) public returns(uint256) {
        require(bytes(title).length > 0, "You have to give the service subscription a name or title.");
        if (cycleLength == 0) revert InvalidCycleLengthError(cycleLength);
        require(endDate == 0 || endDate > block.timestamp, "End date must be 0 for no end date, or set to a future date.");

        uint256 subscriptionId = nextSubscriptionId++;
           subscriptions[subscriptionId] = Subscription({
            subscriptionId: subscriptionId,
            title: title,
            ownerAddress: msg.sender,
            fee: fee,
            cycleLength: cycleLength,
            status: SubscriptionStatus.Active,
            paused: false,
            endDate: endDate, // 0 = betyder att det aldrig upphör automatiskt
            startDate: block.timestamp
        });

        subscribers[msg.sender].push(subscriptionId);
        emit SubCreated(subscriptionId, msg.sender, title, fee, cycleLength, endDate, startDate);
        return subscriptionId;
    }

// Function for owners to manage their subscription service's fee
    function manageSub(uint256 subscriptionId, uint256 newFee, SubscriptionStatus newStatus) public onlySubOwner(subscriptionId) {
        if (subscriptionId >= nextSubscriptionId) revert SubNotExistsError(subscriptionId);
        
        Subscription storage subscription = subscriptions[subscriptionId];
        subscription.fee = newFee;
        subscription.status = newStatus;
        
        emit SubUpdated(subscriptionId, newFee);
        emit SubStatusChanged(subscriptionId, newStatus);
    }

// Function for owners to withdraw the revenue
function withdrawRevenue(uint256 subscriptionId) external onlySubOwner(subscriptionId) {
    
    emit RevenueWithdrawn(subscriptionId, msg.sender, 0);
}

 // -- FUNCTIONS FOR SUBSCRIBERS -- //  

// Function for subscribers to start subscribing by ID
    function subscribe(uint256 subscriptionId, uint256 fee) external 
        payable 
        subExists(subscriptionId) 
        subActive(subscriptionId)  {
        Subscription storage subscription = subscriptions[subscriptionId];
        if (msg.value != fee) revert NotEnoughETHError(msg.value, fee);
        if (fee < subscription.fee) revert NotEnoughETHError(fee, subscription.fee);
        if (userSubscriptions[msg.sender][subscriptionId]) revert AlreadySubscribedError(msg.sender, subscriptionId);
        
        userSubscriptions[msg.sender][subscriptionId] = true; // Markera användaren som prenumerant
        userSubscriptionStart[msg.sender][subscriptionId] = block.timestamp; // Spara starttid
        payable(subscription.ownerAddress).transfer(msg.value);
    }

// Function for subscribers to be able to pause their subscription by the ID
    function pauseSub(uint256 subscriptionId) public {
        if (subscriptionId >= nextSubscriptionId) revert SubNotExistsError(subscriptionId);
        if (!userSubscriptions[msg.sender][subscriptionId]) revert NotSubscribedError(msg.sender, subscriptionId);
        
        userSubscriptions[msg.sender][subscriptionId] = false;
    }

// Function for subscribers to be able to give away their subscription 
function giveawaySub(uint256 subscriptionId, address sendingTo) public {
    require(subscriptionId < nextSubscriptionId, SubNotExistsError());
    require(userSubscriptions[msg.sender][subscriptionId], "You are not subscribed to this service.");
    
    userSubscriptions[msg.sender][subscriptionId] = false;
    userSubscriptions[sendingTo][subscriptionId] = true;
    userSubscriptionStart[sendingTo][subscriptionId] = userSubscriptionStart[msg.sender][subscriptionId]; // Behåll ursprunglig starttid
}

// Function for subscribers to check if they subscribe to this subscription ID
function checkMySubscriptionStatus(uint256 subscriptionId) public view returns (string memory) {
    if (subscriptionId >= nextSubscriptionId) {
        return "This subscription does not exist.";
    }
    if (userSubscriptions[msg.sender][subscriptionId]) {
        return "Yes, you are subscribed to this service.";
    } else {
        return "No, you do not have this subscription.";
    }
}

// Function for subscribers to get their subscription end date
function getSubscriptionEndDate(uint256 subscriptionId) public view returns (uint256) {
    return subscriptions[subscriptionId].endDate;
}
}