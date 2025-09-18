// Det smarta kontraktet för min prenumerationstjänst
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract SmartSub {
    address public owner;
    
// Strukturer & Enums
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
    uint256 public nextSubscriptionId; // Gör ett ID tillgängligt för nästa skapade prenumeration
    uint256 public nextSubscriberId; // Gör ett ID tillgängligt för nästa skapade prenumerant

// Mappings
    mapping(uint256 => Subscription) public subscriptions;
    mapping(address => uint256[]) public subscribers;
    mapping(address => mapping(uint256 => bool)) public userSubscriptions; // Spåra vilka användare som prenumererar på vad
    mapping(address => mapping(uint256 => uint256)) public userSubscriptionStart; // När prenumerationen startade
    mapping(address => mapping(uint256 => uint256)) public userSubscriptionExpiry; // När användarens prenumeration löper ut
    mapping(address => uint) public balances;
    mapping(uint256 => uint256) public subscriptionBalances; // Balans per prenumeration



// Events
    event SubCreated(uint256 indexed subscriptionId, address indexed ownerAddress, string title, uint256 fee, uint256 cycleLength, uint256 endDate, uint256 startDate);
    event SubUpdated(uint256 indexed subscriptionId, uint256 newFee);
    event SubStatusChanged(uint256 indexed subscriptionId, SubscriptionStatus status);
    event SubTransferred(uint256 indexed subscriptionId, address indexed from, address indexed to);
    event RevenueWithdrawn(uint256 indexed subscriptionId, address indexed ownerAddress, uint256 amount);
    event FallbackCalled(address indexed subscriberAddress);
    event OwnerSet(address indexed ownerAddress, string message);
    event SubscribedToSub(uint256 indexed subscriptionId, address indexed subscriberAddress);
    event SubscriptionRenewed(uint256 indexed subscriptionId, address indexed subscriber, uint256 newExpiryDate);
    event SubscriptionExpired(uint256 indexed subscriptionId, address indexed subscriber);

// Custom errors
error OnlySubOwnerError(address caller, address actualOwner);
error SubscriptionNotFound(uint256 subscriptionId);
error SubIsPausedError(uint256 subscriptionId);
error InvalidCycleLengthError(uint256 providedLength);
error NotEnoughETHError(uint256 provided, uint256 required);
error AlreadySubscribedError(address subscriber, uint256 subscriptionId);
error NotSubscribedError(address subscriber, uint256 subscriptionId);


// Konstruktor
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
            revert SubscriptionNotFound(subscriptionId);
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

// Fallback om en funktion anropas som inte finns
fallback() external {
    emit FallbackCalled(msg.sender);
    revert("The function you called does not exist, try another one.");
}

// receive() returnerar ETH om pengar skickas till en funktion som inte finns
receive() external payable { 
    // Returnera pengarna omedelbart till avsändaren
    payable(msg.sender).transfer(msg.value);
    revert("This function does not exist, ETH is returned to you.");
}

 // -- FUNKTIONER FÖR ÄGARE -- //  

// Funktion för ägare att skapa en ny prenumerationstjänst
    function createSub(string memory title, uint256 fee, uint256 cycleLength, uint256 endDate) public returns(uint256) {
        require(bytes(title).length > 0, "You have to give the service subscription a name or title.");
        require(cycleLength > 0, "Cycle length must be greater than 0.");
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
            endDate: endDate, // 0 = aldrig upphörande prenumeration
            startDate: block.timestamp
        });

        subscribers[msg.sender].push(subscriptionId);
        emit SubCreated(subscriptionId, msg.sender, title, fee, cycleLength, endDate, block.timestamp);
        return subscriptionId;
    }

// Funktion för ägare att hantera sin prenumerationstjänsts avgift
    function manageSub(uint256 subscriptionId, uint256 newFee, SubscriptionStatus newStatus) public onlySubOwner(subscriptionId) {
        if (subscriptionId >= nextSubscriptionId) revert SubscriptionNotFound(subscriptionId);
        
        Subscription storage subscription = subscriptions[subscriptionId];
        subscription.fee = newFee;
        subscription.status = newStatus;
        
        emit SubUpdated(subscriptionId, newFee);
        emit SubStatusChanged(subscriptionId, newStatus);
    }

// Funktion för ägare att ta ut intäkterna från en specifik prenumeration
function withdrawRevenue(uint256 subscriptionId) external onlySubOwner(subscriptionId) {
    uint256 amountToTransfer = subscriptionBalances[subscriptionId];
    require(amountToTransfer > 0, "No funds available for this subscription");

    subscriptionBalances[subscriptionId] = 0; // Säkerhet mot återinträde
    payable(msg.sender).transfer(amountToTransfer);

    emit RevenueWithdrawn(subscriptionId, msg.sender, amountToTransfer);
}

// Hjälpfunktion för att se balans för en specifik prenumeration
function getSubscriptionBalance(uint256 subscriptionId) public view 
    onlySubOwner(subscriptionId) returns (uint256) {
    return subscriptionBalances[subscriptionId];
}

 // -- FUNKTIONER FÖR PRENUMERANTER -- //  

// Funktion för prenumeranter att börja prenumerera med ID
    function subscribe(uint256 subscriptionId, uint256 fee) external 
        payable 
        subExists(subscriptionId) 
        subActive(subscriptionId)  {
        Subscription storage subscription = subscriptions[subscriptionId];
        if (userSubscriptions[msg.sender][subscriptionId]) revert AlreadySubscribedError(msg.sender, subscriptionId);
        if (msg.value < subscription.fee) {
            revert NotEnoughETHError(msg.value, subscription.fee);
        }
        require(msg.value == fee, "The ETH amount sent must match the fee parameter.");
        require(fee >= subscription.fee, "Fee must be at least the subscription fee.");
        
        userSubscriptions[msg.sender][subscriptionId] = true; 
        userSubscriptionStart[msg.sender][subscriptionId] = block.timestamp;
        userSubscriptionExpiry[msg.sender][subscriptionId] = block.timestamp + subscription.cycleLength;
        
        assert(userSubscriptions[msg.sender][subscriptionId] == true);
        
        subscriptionBalances[subscriptionId] += msg.value;

        emit SubscribedToSub(subscriptionId, msg.sender);
    }

// Funktion för prenumeranter att förnya sin prenumeration
    function renewSubscription(uint256 subscriptionId) external payable 
        subExists(subscriptionId) 
        subActive(subscriptionId) {
        
        Subscription storage subscription = subscriptions[subscriptionId];
        
        // Kontrollera att användaren redan prenumererar
        require(userSubscriptions[msg.sender][subscriptionId], "You are not subscribed to this service");
        require(msg.value >= subscription.fee, "Insufficient payment for renewal");
        
        uint256 currentExpiry = userSubscriptionExpiry[msg.sender][subscriptionId];
        uint256 newExpiry;
        
        if (currentExpiry > block.timestamp) {
            newExpiry = currentExpiry + subscription.cycleLength;
        } else {
            newExpiry = block.timestamp + subscription.cycleLength;
        }
        
        userSubscriptionExpiry[msg.sender][subscriptionId] = newExpiry;
        subscriptionBalances[subscriptionId] += msg.value;
        
        emit SubscriptionRenewed(subscriptionId, msg.sender, newExpiry);
    }

// Funktion för prenumeranter att kunna pausa sin prenumeration med ID
    function pauseSub(uint256 subscriptionId) public {
        if (subscriptionId >= nextSubscriptionId) revert SubscriptionNotFound(subscriptionId);
        if (!userSubscriptions[msg.sender][subscriptionId]) revert NotSubscribedError(msg.sender, subscriptionId);
        
        userSubscriptions[msg.sender][subscriptionId] = false;
    }

// Funktion för prenumeranter att kunna ge bort sin prenumeration 
function giveawaySub(uint256 subscriptionId, address sendingTo) public {
    if (!userSubscriptions[msg.sender][subscriptionId]) revert NotSubscribedError(msg.sender, subscriptionId);
    
    userSubscriptions[msg.sender][subscriptionId] = false;
    userSubscriptions[sendingTo][subscriptionId] = true;
    
    // Överför både starttid och förfallodatum
    userSubscriptionStart[sendingTo][subscriptionId] = userSubscriptionStart[msg.sender][subscriptionId];
    userSubscriptionExpiry[sendingTo][subscriptionId] = userSubscriptionExpiry[msg.sender][subscriptionId];
    
    emit SubTransferred(subscriptionId, msg.sender, sendingTo);
}

// Funktion för prenumeranter att kontrollera om de prenumererar på detta prenumerations-ID
function checkMySubscriptionStatus(uint256 subscriptionId) public view returns (string memory) {
    if (subscriptionId >= nextSubscriptionId) {
        return "This subscription does not exist.";
    }
    
    Subscription storage subscription = subscriptions[subscriptionId];
        if (subscription.status == SubscriptionStatus.Paused) {
        return "This service is currently paused by the owner.";
    }
        if (subscription.endDate != 0 && block.timestamp > subscription.endDate) {
        return "This service has ended.";
    }
        if (!userSubscriptions[msg.sender][subscriptionId]) {
        return "No, you do not have this subscription.";
    }
    uint256 userExpiry = userSubscriptionExpiry[msg.sender][subscriptionId];
    if (block.timestamp > userExpiry) {
        return "Your subscription has expired. Please renew to continue access.";
    }
    
    return "Yes, you have an active subscription to this service.";
}


// Funktion för prenumeranter att få sitt eget prenumerations slutdatum
function getMySubscriptionEndDate(uint256 subscriptionId) public view returns (uint256) {
    if (subscriptionId >= nextSubscriptionId) return 0;
    if (!userSubscriptions[msg.sender][subscriptionId]) return 0;
    
    return userSubscriptionExpiry[msg.sender][subscriptionId];
}
}