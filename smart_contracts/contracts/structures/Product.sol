// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15 <0.9.0;


import "./State.sol";
import "./ProductOwner.sol";

struct Product {
    uint256 id; // Universal Product Code (UPC) - unique to the product
    uint256 productType;
    address createdBy; // address of the manufacturer
    uint256 createdAt;
    uint256 expiresAt;
    uint256 lastPrice;
    ProductOwner[] ownershipHistory; 
    State[] stateHistory;

    bytes32 specification; //hash data in ipfs

    // todo: we need to block product somehow while it's in order (for only confirmed order)
    bool isBlockedFromOrdering; // if true then this product has already been addded to order
}
