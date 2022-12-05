// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15 <0.9.0;

import "./OrderMember.sol";
import "./ProductInOrder.sol";
import "./OrderState.sol";

struct Order {
    uint256 id;
    ProductInOrder[] productList;
    uint256 createdAt;
    address createdBy;
    OrderMember buyer;
    OrderMember seller;
    OrderState[] orderStateList;
}
