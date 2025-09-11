// The Smart Contact for my subscription service

// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

contract SmartSub {
    address public owner;
    
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

    constructor() {
        owner = msg.sender;
        eventCounter = 0;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    function paySub(address _subscriber, uint256 _fee) public {
        require(subs[_subscriber].owner != address(0), "Subscriber not registered");
    }
}

