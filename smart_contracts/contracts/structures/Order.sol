// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15 <0.9.0;

import "./OrderMember.sol";
import "./ProductInOrder.sol";
import "./OrderState.sol";
import "../enums/OrderMode.sol";

struct Order {
    uint256 id;
    OrderMode mode;
    ProductInOrder[] productList;
    uint256 createdAt;
    address createdBy;
    OrderMember buyer;
    OrderMember seller;
    OrderState[] orderStateList;
}
