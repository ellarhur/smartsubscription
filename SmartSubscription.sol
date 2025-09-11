// The Smart Contact for my subscription service

// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

contract SmartSub {
       // ---- Reentrancy-guard ----
    uint256 private _locked = 1;
    modifier nonReentrant() {
        require(_locked == 1, "Reentrant call");
        _locked = 2;
        _;
        _locked = 1;
    }

    address public owner;
    
    // ---- Struct & Enums ----
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
}

