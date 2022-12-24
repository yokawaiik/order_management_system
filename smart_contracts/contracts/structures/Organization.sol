// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15 <0.9.0;

struct Organization {
    uint256 id;
    string title;
    uint256 createdAt;
    address createdBy;
    uint256[] inventory;
    bool isStopped;
}
