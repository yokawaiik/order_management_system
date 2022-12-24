// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15 <0.9.0;

import "../enums/StateList.sol";

struct State {
    StateList state;
    uint256 date;
    uint256 price;
    address createdBy; // who changed it
    string description; // maybe here needs to make a hash from ipfs
}
