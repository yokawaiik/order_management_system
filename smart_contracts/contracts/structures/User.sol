// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15 < 0.9;

struct User {
    uint256 id;
    address userAddress;
    string login; // todo: remove it maybe
    string password; // todo: remove it maybe
    bytes32 role;
    uint256 createdAt;
    uint256[] inventory;
}
