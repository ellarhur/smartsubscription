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

   //  Modifiers
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


    function createSub(string memory subTitle, uint256 subFee, uint256 cycleLength, subStatus status) public {
    require(cycleLength > 0, "You have to set a period for the subscription"); // Make sure the owner sets a period
    uint256 subscriptionId = subscriptionCounter++;
    subscriptions[subscriptionId] = Subscription({
        owner: msg.sender,
        title: subTitle,
        fee: subFee,
        cycleLength: daysBetween * 1 days, // gör om dagar till sekunder
        status: status,
        startDate: block.timestamp,
        endDate: block.timestamp + cycleLength,
        balance: 0,
        paused: false
    });
    }




// function paySub(address _subscriber, uint256 _fee) public nonReentrant { 


// function extendSub(address _subscriber) public nonReentrant {


// function isActive(address _subscriber) public view returns (bool) {


// function getEndDate(address _subscriber) public view returns (uint256) {


// // function giveawaySub(address _subscriber) public nonReentrant {

// function changeFee(uint256 _fee) public nonReentrant {


// function pauseSub(address _subscriber) public nonReentrant {


// function resumeSub(address _subscriber) public nonReentrant {


// function collectRevenue() public nonReentrant {



}