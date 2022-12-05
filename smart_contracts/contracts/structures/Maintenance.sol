// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15 <0.9.0;

import "../structures/MaintenanceMember.sol";
import "./MaintenanceState.sol";

struct Maintenance {
    uint256 id;
    // todo: for every manufacturer: mapping(uint => uint[])
    // todo: uint[] manufacturers
    uint256 product;
    uint256 createdAt;
    MaintenanceMember giver;
    MaintenanceMember receiver;
    MaintenanceState[] maintenanceStateList;
}
