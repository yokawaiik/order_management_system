// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15 <0.9.0;

import "../enums/OrderStateList.sol";

struct OrderState {
    OrderStateList state;
    bytes32 descriptionHash;
    address createdBy;
    uint256 createdAt;
}
