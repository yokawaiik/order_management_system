// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15 <0.9.0;

import "../../node_modules/@openzeppelin/contracts/access/AccessControl.sol";
import "../structures/User.sol";
import "../enums/OrganizationRoles.sol";
import "../libraries/StringLibrary.sol";
import "../structures/Organization.sol";

contract AccessControlManager is AccessControl {
    // ? info, app has a methods by AccessControl:
    // ?  grantRole
    // ?  revokeRole
    // ?  renounceRole
    // ? info: constants
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE"); // contract deployer
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant ADMIN_ORGANIZATION_ROLE =
        keccak256("ADMIN_ORGANIZATION_ROLE");
    // ? info: it can produce products
    bytes32 public constant MANUFACTURER_ROLE = keccak256("MANUFACTURER_ROLE");
    bytes32 public constant SELLER_ROLE = keccak256("SELLER_ROLE");
    bytes32 public constant SIMPLE_USER_ROLE = keccak256("SIMPLE_USER_ROLE");
    uint256 public constant TIME_TO_CORRECT_MISTAKE = 60 * 15;

    constructor() {
        _setRoleAdmin(DEFAULT_ADMIN_ROLE, ADMIN_ROLE);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(OWNER_ROLE, msg.sender);

        createUser(msg.sender, "owner", "owner", ADMIN_ROLE);
    }

    function revokeRole(bytes32 role, address account)
        public
        override
        onlyRole(ADMIN_ROLE)
    {
        if (role == OWNER_ROLE || role == ADMIN_ROLE)
            require(
                hasRole(OWNER_ROLE, msg.sender) == true,
                "Revoke admins and owners are available only for contract's owner."
            );

        _revokeRole(role, account);
    }

    function grantRole(bytes32 role, address account)
        public
        override
        onlyRole(ADMIN_ROLE)
    {
        if (role == OWNER_ROLE || role == ADMIN_ROLE)
            require(
                hasRole(OWNER_ROLE, msg.sender) == true,
                "Grant role admins and owners are available only for contract's owner."
            );

        _grantRole(role, account);
    }

    mapping(address => User) internal users;
    mapping(uint256 => Organization) internal organizations;
    uint256 private organizationIdCounter;

    function createUser(
        address _userAddress,
        string memory _login,
        string memory _password,
        bytes32 _role
    ) public onlyRole(ADMIN_ROLE) {
        // ? info: need to have access to add a new user

        // other admin can't delete admin-owner

        require(
            users[_userAddress].createdAt == 0,
            "Such user has already been created."
        );

        if ((_role == ADMIN_ROLE || _role == OWNER_ROLE)) {
            require(
                hasRole(OWNER_ROLE, msg.sender) == true,
                "Set up admins and owners are available only for contract's owner."
            );
        }

        users[_userAddress].userAddress = _userAddress;

        users[_userAddress].password = StringLibrary.hash(_password);
        users[_userAddress].login = _login;

        users[_userAddress].createdAt = block.timestamp;
        users[_userAddress].role = _role;
        grantRole(_role, msg.sender);
    }

    // can update user on his own
    function updateUserInfo(
        address _userAddress,
        string memory _login,
        string memory _password
    ) public {
        User storage user = _getUserByAddress(msg.sender);

        user.userAddress = _userAddress;
        user.password = StringLibrary.hash(_password);
        user.login = _login;
    }

    // create a simple user by an organization employe
    function addBuyer(
        uint256 _organizationId,
        address _userAddress,
        string memory _login,
        string memory _password
    ) public onlyOrganizationEmploye(_organizationId) {
        createUser(_userAddress, _login, _password, SIMPLE_USER_ROLE);
    }

    // Add organization
    function createOrganization(string memory _title)
        public
        onlyRole(ADMIN_ORGANIZATION_ROLE)
        returns (uint256)
    {
        uint256 timestamp = block.timestamp;
        Organization storage newOrg = organizations[organizationIdCounter];
        newOrg.id = organizationIdCounter;
        newOrg.title = _title;
        newOrg.createdAt = timestamp;
        newOrg.createdBy = msg.sender;

        OrganizationMember storage admin = users[msg.sender].organizationMember;
        admin.addedAt = timestamp;
        admin.role = OrganizationRoles.Admin;
        admin.organizationId = organizationIdCounter;

        ++organizationIdCounter;

        return newOrg.id;
    }

    modifier onlyOrganizationEmploye(uint256 _organizationId) {
        _getOrganizationById(_organizationId);
        OrganizationMember memory employe = users[msg.sender]
            .organizationMember;
        require(
            employe.addedAt != 0 && employe.organizationId == _organizationId,
            "You aren't an employe of this organization."
        );

        require(
            employe.role != OrganizationRoles.None,
            "You're an employe of this organization, but you can't cat any action."
        );

        _;
    }
    modifier onlyOrganizationAdmin(uint256 _organizationId) {
        Organization storage organization = _getOrganizationById(
            _organizationId
        );
        OrganizationMember memory employe = _getUserByAddress(msg.sender)
            .organizationMember;

        require(
            employe.role == OrganizationRoles.Admin,
            "This action is available only for organization admin."
        );
        _;
    }
    modifier onlyOrganizationSeller(uint256 _organizationId) {
        OrganizationMember memory employe = _getUserByAddress(msg.sender)
            .organizationMember;

        require(
            employe.organizationId != _organizationId,
            "You aren't an employe of this organization."
        );

        require(
            employe.role != OrganizationRoles.None,
            "You have a role 'None' and you can't act this action."
        );

        _;
    }

    function getOrganizationById(uint256 _organizationId)
        public
        view
        returns (Organization memory)
    {
        Organization memory organization = _getOrganizationById(
            _organizationId
        );
        return organization;
    }

    function _getOrganizationById(uint256 _organizationId)
        internal
        view
        returns (Organization storage)
    {
        Organization storage organization = organizations[_organizationId];

        require(organization.createdAt != 0, "Organization doesn't exist.");

        return organization;
    }

    // add employe or change his role
    function addEmployeToOrganization(
        uint256 _organizationId,
        address _employeAddress,
        OrganizationRoles _role
    ) public onlyOrganizationAdmin(_organizationId) {
        uint256 timestamp = block.timestamp;

        OrganizationMember storage employe = _getUserByAddress(_employeAddress)
            .organizationMember;
        employe.addedAt = timestamp;
        employe.role = _role;
        employe.organizationId = _organizationId;

        if (_role == OrganizationRoles.Admin) {
            _grantRole(SELLER_ROLE, _employeAddress);
            _grantRole(ADMIN_ORGANIZATION_ROLE, _employeAddress);
        } else {
            _grantRole(SELLER_ROLE, _employeAddress);
        }
    }

    function deleteEmployeFromOrganization(
        uint256 _organizationId,
        address _employeAddress
    ) public onlyOrganizationAdmin(_organizationId) {
        Organization storage organization = _getOrganizationById(
            _organizationId
        );

        OrganizationMember storage currentEmploye = _getUserByAddress(
            msg.sender
        ).organizationMember;

        OrganizationMember storage deletedEmploye = _getUserByAddress(
            _employeAddress
        ).organizationMember;

        require(
            currentEmploye.role == OrganizationRoles.Admin,
            "You don't have rights for this action."
        );

        if (deletedEmploye.role == OrganizationRoles.Admin) {
            require(
                organization.createdBy == msg.sender,
                "Only creator can delete admins of the organization."
            );
        }

        // delete organization information
        deletedEmploye.addedAt = 0;
        deletedEmploye.organizationId = 0;
        deletedEmploye.role = OrganizationRoles.None;
        _revokeRole(SELLER_ROLE, _employeAddress);
        _revokeRole(ADMIN_ORGANIZATION_ROLE, _employeAddress);
    }

    function getOrganizationInventoryById(uint256 _organizationId)
        internal
        view
        returns (uint256[] memory)
    {
        uint256[] memory inventory = _getOrganizationInventoryById(
            _organizationId
        );
        return inventory;
    }

    function _getOrganizationInventoryById(uint256 _organizationId)
        internal
        view
        onlyOrganizationEmploye(_organizationId)
        returns (uint256[] storage)
    {
        uint256[] storage inventory = _getOrganizationById(_organizationId)
            .inventory;

        return inventory;
    }

    // ? info: find user by address
    function _getUserByAddress(address _userAddress)
        internal
        view
        returns (User storage)
    {
        User storage user = users[_userAddress];

        require(user.createdAt != 0, "User with such an address wasn't find.");
        return user;
    }

    // ? info: find user by address
    function getUserByAddress(address _userAddress)
        public
        view
        returns (User memory)
    {
        User memory user = _getUserByAddress(_userAddress);
        user.password = "";
        return user;
    }

    function exportOrganization(uint256 _organizationId)
        external
        view
        onlyRole(OWNER_ROLE)
        returns (Organization memory)
    {
        Organization memory organization = _getOrganizationById(
            _organizationId
        );
        return organization;
    }

    function exportUser(address _userAddress)
        external
        view
        onlyRole(OWNER_ROLE)
        returns (User memory)
    {
        return _getUserByAddress(_userAddress);
    }

    function _checkProductInInventory(
        uint256 _productId,
        uint256[] storage _inventory
    ) internal view returns (bool) {
        for (uint256 i = 0; i < _inventory.length; i++) {
            if (_inventory[i] == _productId) {
                return true;
            }
        }
        return false;
    }

    function _removeProductFromInventory(
        uint256 _productId,
        uint256[] storage _inventory
    ) internal {
        require(
            _checkProductInInventory(_productId, _inventory) == true,
            "Such a product was not find in inventory."
        );

        for (uint256 i = 0; i < _inventory.length; i++) {
            if (_inventory[i] == _productId) {
                for (uint256 j = i; j < _inventory.length - 1; j++) {
                    _inventory[j] = _inventory[j + 1];
                }
                _inventory.pop();
                break;
            }
        }
    }

    function _addProductToInventory(
        uint256 _productId,
        uint256[] storage _inventory
    ) internal {
        _inventory.push(_productId);
    }
}
