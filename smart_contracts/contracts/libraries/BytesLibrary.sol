// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15 <0.9.0;

library BytesLibrary {
    function compareBytes(bytes32 b1, bytes32 b2)
        public
        pure
        returns (bool)
    {
        return b1 == b2;
    }
}
