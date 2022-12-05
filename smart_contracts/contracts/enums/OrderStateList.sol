// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15 <0.9.0;

enum OrderStateList {
    Unhandled, // 0
    Processing,
    InTransit,
    Delivered,
    Received
}