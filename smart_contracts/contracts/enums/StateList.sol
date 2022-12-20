// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15 <0.9.0;

enum StateList {
    // ? info: Basic StateList
    Unhandled, 
    Produced, 
    InTransit, 
    InWarehouse, 
    OnSale, 
    Sold, 
    Removed, 
    // ? info: Ensuring originality
    WasCompromised, 
    // ? info: Maintenance
    InService, 
    WasFinished, 
    WasDeny, 
    WasGotByOwner,
    // ? info: only for Manufacturer
    WasDestroyed, 
    WasRestored, 
    // ? info: Owner conception
    OwnerWasChanged, 
    PriceWasChanged, 

    // ? maintenance
    
    Refused, // 
    Gave, //  user gave his product
    Received, //  user receive his product come back | repairer received product by user
    Returned //  repairer returned product by user
}
