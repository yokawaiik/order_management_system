// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15 <0.9.0;

enum StateList {
    // ? info: Basic StateList
    Unhandled, // 0
    Produced, // 1
    InTransit, // 2
    InWarehouse, // 3
    OnSale, // 4
    Sold, // 5
    Removed, // 6
    // ? info: Ensuring originality
    WasCompromised, // 7
    // ? info: Service and Maintenance
    WasServiced, // 8
    WasDestroyed, // 9
    WasRestored, // 10
    // ? info: Owner conception
    OwnerWasChanged, // 11
    PriceWasChanged // 12
}
