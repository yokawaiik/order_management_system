// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15 <0.9.0;


import "../enums/OrderMemberDecision.sol";


struct OrderMember {
   uint organizationId;
   address userAddress;
   bool transferred;
   OrderMemberDecision decision;
}
