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

    struct Sub {
        address owner;
        uint256 fee;
        uint256 periodLength;
        bool paused;
        uint256 balance;
    }

    mapping(address => Sub) public subs;
    mapping(address => bool) public isRegistered;
    uint256 public eventCounter;

    // Constructor
    constructor() {
        owner = msg.sender;
        eventCounter = 0;
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