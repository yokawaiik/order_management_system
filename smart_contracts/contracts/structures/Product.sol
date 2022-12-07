// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15 <0.9.0;


import "./State.sol";
import "./ProductOwner.sol";

struct Product {
    uint256 id; // Universal Product Code (UPC) - unique to the product
    uint256 productType;
    ProductOwner owner; // address of the current owner as the equipment moves though the supply chain 
    address createdBy; // address of the manufacturer
    uint256 createdAt;
    uint256 expiresAt;
    uint256 lastPrice;
    State lastState;
    ProductOwner[] ownershipHistory; 
    State[] stateHistory;
    bytes32 specification; //hash data in ipfs
}
