// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15 <0.9.0;

import"../enums/OrderStateList.sol";

struct OrderState {
    string location;
    OrderStateList state;
    string description;
    address user;
    
}
