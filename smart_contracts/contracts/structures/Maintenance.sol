// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15 <0.9.0;

import "../structures/MaintenanceMember.sol";

struct Maintenance {
    uint256 id;
    uint256 product;
    uint256 createdAt;
    MaintenanceMember giver;
    MaintenanceMember receiver;
    string description;
}
