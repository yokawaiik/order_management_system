// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15 <0.9.0;

import "../enums/StateList.sol";

struct OrderState {
    string location;
    StateList state;
    string description;
    address user;
}
