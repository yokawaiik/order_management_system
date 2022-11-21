// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15 <0.9.0;

enum MaintenanceMemberDecision {
    Unhandled, // 0
    Refused, // 1
    Gave, // 2 - user gave his product
    Received, // 3 - user receive his product come back | repairer received product by user
    Returned // 4 - repairer returned product by user
}
