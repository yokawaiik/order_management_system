// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15 < 0.9;
// library
import "../../node_modules/@openzeppelin/contracts/access/AccessControl.sol";

import "../structures/User.sol";

contract AccessControlManager is AccessControl {
    // ? info: constants
    // ? info: all roles for app
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE"); // contract deployer
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE"); // ? info: IoT

    bytes32 public constant MANUFACTURER_ROLE = keccak256("MANUFACTURER_ROLE");
    bytes32 public constant SUPPLIER_ROLE = keccak256("SUPPLIER_ROLE");
    bytes32 public constant TRANSPORTER_ROLE = keccak256("TRANSPORTER_ROLE");
    bytes32 public constant BUYER_ROLE = keccak256("BUYER_ROLE");
    bytes32 public constant SERVICE_ROLE = keccak256("SERVICE_ROLE");

    uint256 public constant TIME_TO_CORRECT_MISTAKE = 15 * 60;

    // ? info: app has a method - grantRole
    // ? info: app has a method - revokeRole
    // ? info: app has a method - renounceRole

    // ? info: modifiers
    // ? info: permissions
    modifier onlyMerchants() {
        string memory message = "This action available only for owner.";
        require(
            hasRole(MANUFACTURER_ROLE, msg.sender) ||
                hasRole(SUPPLIER_ROLE, msg.sender) ||
                hasRole(TRANSPORTER_ROLE, msg.sender) ||
                hasRole(ORACLE_ROLE, msg.sender),
            message
        );
        _;
    }

    modifier severalRoles(bytes32[] memory _roles) {
        for (uint256 index = 0; index < _roles.length; index++) {
            if (hasRole(_roles[index], msg.sender)) {
                break;
                _;
            }
        }
        revert("This action available only for allowed roles.");
    }

    modifier onlyTransporters() {
        require(
            hasRole(TRANSPORTER_ROLE, msg.sender) ||
                hasRole(TRANSPORTER_ROLE, msg.sender),
            "This action available only for transporter."
        );
        _;
    }

    constructor() {
        // todo: check or remove
        _setRoleAdmin(DEFAULT_ADMIN_ROLE, ADMIN_ROLE);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    mapping(uint256 => User) internal users;
    uint256 private userIdCounter;

    function addUser(
        address _userAddress,
        string memory _login,
        string memory _password,
        bytes32 _role
    ) public onlyRole(ADMIN_ROLE) {
        users[userIdCounter].id = userIdCounter;
        users[userIdCounter].userAddress = _userAddress;
        users[userIdCounter].password = _password;
        users[userIdCounter].login = _login;
        users[userIdCounter].createdAt = block.timestamp;
        users[userIdCounter].role = _role;

        ++userIdCounter;
    }

    function addBuyer(
        address _userAddress,
        string memory _login,
        string memory _password
    ) public {
        users[userIdCounter].id = userIdCounter;
        users[userIdCounter].userAddress = _userAddress;
        users[userIdCounter].password = _password;
        users[userIdCounter].login = _login;
        users[userIdCounter].createdAt = block.timestamp;
        users[userIdCounter].role = BUYER_ROLE;

        ++userIdCounter;
    }

    function getUsersCount() public view returns (uint256) {
        return userIdCounter;
    }

    // ? info: find user by id
    function findUserById(uint256 _userId) public view returns (User memory) {
        User memory user = users[_userId];
        user.password = "";
        require(user.createdAt == 0, "User with such an id wasn't find.");

        return users[_userId];
    }

    function findUserIdByAddress(address _userAddress)
        public
        view
        returns (uint256)
    {
        uint256 foundUserId;

        for (uint256 i = 0; i < userIdCounter; i++) {
            if (users[i].userAddress == _userAddress) {
                foundUserId = i;
                break;
            }
        }

        require(
            users[foundUserId].createdAt != 0 &&
                users[foundUserId].userAddress != _userAddress,
            "User with such an id wasn't find."
        );

        return foundUserId;
    }

    function _getUserById(uint256 _userId)
        internal
        view
        returns (User storage)
    {
        User storage user = users[_userId];

        require(user.createdAt != 0, "User with such an id wasn't find.");

        return user;
    }

    // ? info: find user by address
    function findUserByAddress(address _userAddress)
        public
        view
        returns (User memory)
    {
        uint256 foundUserId = findUserIdByAddress(_userAddress);

        User memory user = findUserById(foundUserId);
        user.password = "";

        return user;
    }

    function exportUsers()
        external
        view
        onlyRole(OWNER_ROLE)
        returns (User[] memory)
    {
        User[] memory memoryArray = new User[](userIdCounter);

        if (userIdCounter == 0) {
            return memoryArray;
        }

        for (uint256 i = 0; i < userIdCounter; i++) {
            memoryArray[i] = users[i];
        }

        return memoryArray;
    }

    // todo: maybe it add in other module
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
        uint256[] storage _inventory,
        uint256 _productId
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
        uint256[] storage _inventory,
        uint256 _productId
    ) internal {
        _inventory.push(_productId);
    }
}
