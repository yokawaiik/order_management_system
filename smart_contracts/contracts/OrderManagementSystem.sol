// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15 <0.9.0;

import "../node_modules/@openzeppelin/contracts/access/AccessControl.sol";

import "./modules/ProductsManager.sol";
import "./modules/AccessControlManager.sol";
import "./modules/OrdersManager.sol";
import "./modules/MaintenanceManager.sol";

contract OrderManagementSystem is
    AccessControlManager,
    ProductsManager,
    OrdersManager,
    MaintenanceManager
{
    // ! todo: add all modules
}
