// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15 <0.9.0;

import "../enums/ProductOwnerType.sol";

struct ProductOwner {
    uint256 id;
    uint256 createdAt;
    ProductOwnerType ownerType;
}