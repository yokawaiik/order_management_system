// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15 < 0.9;

import "../enums/OrganizationRoles.sol";

struct OrganizationMember {
    uint256 addedAt;
    OrganizationRoles role;
    uint256 organizationId;
}
