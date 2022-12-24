// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15 <0.9.0;


enum OrderMemberDecision {
    Unhandled, 
    Agreement, 
    Disagreement, 
    Deleted, 
    Waiting,
    Finished
}
