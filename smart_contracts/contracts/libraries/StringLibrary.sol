// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15 <0.9.0;

library StringLibrary {
    function compareTwoStrings(string memory s1, string memory s2)
        public
        pure
        returns (bool)
    {
        return
            keccak256(abi.encodePacked(s1)) == keccak256(abi.encodePacked(s2));
    }

    function hash(string memory _string) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_string));
    }
}
