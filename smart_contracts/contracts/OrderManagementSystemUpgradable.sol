// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15 <0.9.0;

import "./OrderManagementSystem.sol";

contract OrderManagementSystemUpgradable {
    address private owner;
    uint256 public version;
    address private orderManagementSystemContract;

    constructor() {
        OrderManagementSystem orderManagementSystem = new OrderManagementSystem();
        orderManagementSystemContract = address(orderManagementSystem);
        version = _incrementCounter(version);
    }

    function getContractAddress() public view returns (address) {
        return orderManagementSystemContract;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "This action available only for owner.");
        _;
    }

    function updateContractAddress(address _newContract) public onlyOwner {
        orderManagementSystemContract = _newContract;
        version = _incrementCounter(version);
    }

    function _incrementCounter(uint256 _counter)
        internal
        pure
        returns (uint256)
    {
        return ++_counter;
    }
}
