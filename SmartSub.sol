// The Smart Contact for my subscription service

// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

contract SmartSub {
       // Reentrancy-guard
    uint256 private _locked = 1;
    modifier nonReentrant() {
        require(_locked == 1, "Reentrant call");
        _locked = 2;
        _;
        _locked = 1;
    }

    address public owner;
    
    // Struct & Enums
    enum subStatus { Active, Paused }

    struct Subscription {
        uint256 subscriptionId;
        string title;
        address ownerAddress;
        uint256 fee;
        uint256 periodLength;
        subStatus status;
        uint256 startDate;
        uint256 endDate;
        uint256 balance;
    }

    struct Subscriber {
        uint256 subscriberId;
        address subscriberAddress;
        bool isActive;
        uint256 balance;
    }

// Counters
uint256 public subscriptionCounter;
uint256 public subscriberCounter;

// Mappings
mapping(uint256 => address) public ownerAddress; // Mapping for the owner address of subscriptions
mapping(uint256 => mapping(address => Subscription)) public subscriptions; // Mapping for if the subscribers has an active subscription

    // Constructor
    constructor() {
    owner = msg.sender;
    subscriptionCounter = 0;
    subscriberCounter = 0;
    }

    function addSub(string memory subTitle, uint256 subFee, uint256 periodLength) public {
        for (uint256 i = 0; i < subscriptionCounter; i++) {
                require(subscriptions[i].owner != msg.sender || keccak256(bytes(subscriptions[i].title)) == keccak256(bytes(subTitle)), "Owner already made this subscription"); // Make sure the owner hasn't already created this subscription.
                require(periodLength > 0, "You have to set a period for the subscription"); // Make sure the owner sets a period
        }
        subscriptionCounter++;
        subscriptions[subscriptionCounter][msg.sender] = Subscription(subscriptionCounter, _title, msg.sender, _fee, _periodLength, subStatus.Active, block.timestamp, block.timestamp + _periodLength, 0);
        ownerAddress[subscriptionCounter] = msg.sender;
    }
}



function paySub(address _subscriber, uint256 _fee) public nonReentrant { 
}

function extendSub(address _subscriber) public nonReentrant {
}

function isActive(address _subscriber) public view returns (bool) {
}

function getEndDate(address _subscriber) public view returns (uint256) {
}

function giveawaySub(address _subscriber) public nonReentrant {
}

function changeFee(uint256 _fee) public nonReentrant {
}

function pauseSub(address _subscriber) public nonReentrant {
}

function resumeSub(address _subscriber) public nonReentrant {
}

function collectRevenue() public nonReentrant {
}

event SubCreated(address indexed subscriber, uint256 fee, uint256 periodLength);
event SubPaid(address indexed subscriber, uint256 fee);
event SubExtended(address indexed subscriber, uint256 periodLength);
event SubGiveaway(address indexed subscriber);
event SubPaused(address indexed subscriber);