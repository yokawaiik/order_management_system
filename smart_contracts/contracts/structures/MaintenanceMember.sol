// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15 <0.9.0;

import "../enums/MaintenanceMemberDecision.sol";

struct MaintenanceMember {
   uint256 userId;
   MaintenanceMemberDecision decision;
}
