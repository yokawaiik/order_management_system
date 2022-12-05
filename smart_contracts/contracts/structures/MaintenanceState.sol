// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15 <0.9.0;

import "../enums/StateList.sol";

struct MaintenanceState {
    string location;
    StateList state;
    uint256 createdAt;
    string description;
    address user;
}
