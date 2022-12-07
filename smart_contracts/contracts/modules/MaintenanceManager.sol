// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15 <0.9.0;

import "../structures/Maintenance.sol";
import "../structures/MaintenanceState.sol";

import "./AccessControlManager.sol";
import "./ProductsManager.sol";
import "../enums/StateList.sol";

import "../libraries/StringLibrary.sol";

contract MaintenanceManager is AccessControlManager, ProductsManager {
    event UpdatedMaintenanceMemberState(uint256 maintenanceId, uint256 userId);
    event UpdatedMaintenancState(
        uint256 maintenanceId,
        StateList state,
        string _description,
        uint256 userId
    );
    mapping(uint256 => Maintenance) private maintenanceList;
    uint256 private maintenanceIdCounter = 0;

    function _getMaintenanceById(uint256 _maintenanceId)
        internal
        view
        onlyMerchants
        returns (Maintenance storage)
    {
        Maintenance storage maintenance = maintenanceList[_maintenanceId];
        require(
            maintenance.createdAt != 0,
            "Such an maintenance wasn't registered."
        );
        return maintenance;
    }

    function getMaintenanceById(uint256 _maintenanceId)
        public
        view
        onlyMerchants
        returns (Maintenance memory)
    {
        return _getMaintenanceById(_maintenanceId);
    }

    modifier onlyMaintenanceMembers(uint256 _maintenanceId) {
        Maintenance memory maintenance = _getMaintenanceById(_maintenanceId);
        uint256 currentUserId = _getUserByAddress(msg.sender).id;

        require(
            maintenance.giver.userId == currentUserId ||
                maintenance.receiver.userId == currentUserId,
            "This action available only for maintenance participants."
        );

        _;
    }

    function exportMaintenance()
        external
        view
        onlyRole(OWNER_ROLE)
        returns (Maintenance[] memory)
    {
        Maintenance[] memory memoryArray = new Maintenance[](
            maintenanceIdCounter
        );

        for (uint256 i = 0; i < maintenanceIdCounter; i++) {
            memoryArray[i] = maintenanceList[i];
        }

        return memoryArray;
    }

    function createMaintenance(
        uint256 _productId,
        string memory _location,
        string memory _description,
        uint256 _giverId,
        uint256 _receiverId
    ) public onlyMerchants {
        User storage giver = _getUserById(_giverId);
        User storage receiver = _getUserById(_receiverId);

        require(
            _checkProductInInventory(_productId, giver.inventory) == true,
            "You don't have such a product in your inventory."
        );

        // todo: can't create if mantenance has already started and wasnt got

        // it can create buyer and merchants
        require(
            (msg.sender == giver.userAddress &&
                hasRole(BUYER_ROLE, msg.sender) == true) ||
                (msg.sender == receiver.userAddress &&
                    hasRole(BUYER_ROLE, msg.sender) != true),
            "This action isn't available for your account type."
        );

        Product storage product = _getProductInStorageById(_productId);

        Maintenance storage newMaintenance = maintenanceList[
            maintenanceIdCounter
        ];

        newMaintenance.id = maintenanceIdCounter;
        newMaintenance.createdAt = block.timestamp;
        newMaintenance.product = product.id;

        newMaintenance.giver = MaintenanceMember(
            giver.id,
            MaintenanceMemberDecision.Gave
        );
        newMaintenance.receiver = MaintenanceMember(
            receiver.id,
            MaintenanceMemberDecision.Unhandled
        );

        updateMaintenanceState(
            newMaintenance.id,
            _location,
            StateList.InService,
            "Maintenance was created."
        );

        updateProductState(
            _productId,
            StateList.InService,
            0, // doesn't change
            string.concat(
                _description,
                "Product in service with id ",
                new string(newMaintenance.id),
                "."
            )
        );

        ++maintenanceIdCounter;
    }

    modifier onlyMaintenanceState(StateList _state) {
        require(
            _state == StateList.InService ||
                _state == StateList.WasFinished ||
                _state == StateList.WasDeny,
            "Available only maintenance states: InService, WasFinished, WasDeny."
        );
        _;
    }

    function updateMaintenanceState(
        uint256 _maintenanceId,
        string memory _location,
        StateList _state,
        string memory _description
    ) public onlyRole(MAINTAINER_ROLE) onlyMaintenanceState(_state) 
    
    {
        Maintenance storage maintenance = _getMaintenanceById(_maintenanceId);

        require(
            maintenance
                .maintenanceStateList[
                    maintenance.maintenanceStateList.length - 1
                ]
                .state != StateList.WasGotByOwner,
            "Unavailable state, because product has already been got by owner."
        );

        MaintenanceState storage currentMaintenanceState = maintenance
            .maintenanceStateList
            .push();

        if (StringLibrary.compareTwoStrings(_description, "")) {
            currentMaintenanceState.description = "No description.";
        } else {
            currentMaintenanceState.description = _description;
        }

        if (StringLibrary.compareTwoStrings(_location, "")) {
            currentMaintenanceState.location = "Undefined";
        } else {
            currentMaintenanceState.location = _location;
        }
        currentMaintenanceState.state = _state;
        currentMaintenanceState.createdAt = block.timestamp;

        currentMaintenanceState.user = msg.sender;

        emit UpdatedMaintenancState(
            _maintenanceId,
            _state,
            _description,
            _getUserByAddress(msg.sender).id
        );
    }

    function updateMaintenanceMemberDecision(
        uint256 _maintenanceId,
        MaintenanceMemberDecision _decision,
        string memory _description
    ) public onlyMaintenanceMembers(_maintenanceId) {
        Maintenance storage maintenance = _getMaintenanceById(_maintenanceId);
        uint256 currentUserId = _getUserByAddress(msg.sender).id;

        if (maintenance.giver.userId == currentUserId) {
            if (
                maintenance.giver.decision ==
                MaintenanceMemberDecision.Received &&
                _decision != MaintenanceMemberDecision.Returned
            ) {
                revert("This decision is not available for your account type.");
            }

            maintenance.giver.decision = _decision;
        } else {
            if (
                maintenance.receiver.decision ==
                MaintenanceMemberDecision.Received &&
                _decision != MaintenanceMemberDecision.Unhandled
            ) {
                revert("This decision is not available for your account type.");
            }
            maintenance.receiver.decision = _decision;
        }

        User storage giver = _getUserById(maintenance.giver.userId);
        User storage receiver = _getUserById(maintenance.receiver.userId);

        // ? info : users transferring product each other in inventory
        if (
            maintenance.giver.decision == MaintenanceMemberDecision.Gave &&
            maintenance.receiver.decision == MaintenanceMemberDecision.Received
        ) {
            _removeProductFromInventory(giver.inventory, maintenance.product);
            _addProductToInventory(receiver.inventory, maintenance.product);
        } else if (
            maintenance.receiver.decision == MaintenanceMemberDecision.Gave &&
            maintenance.giver.decision == MaintenanceMemberDecision.Received
        ) {
            _removeProductFromInventory(
                receiver.inventory,
                maintenance.product
            );
            _addProductToInventory(giver.inventory, maintenance.product);
        }

        updateProductState(
            maintenance.product,
            StateList.InService,
            0,
            _description
        );

        emit UpdatedMaintenanceMemberState(_maintenanceId, currentUserId);
    }
    // todo: divide this method into
    // todo:  updateMaintenanceMemberDecisionByUser
    // todo:  updateMaintenanceMemberDecisionByMerchant


    // ? info : when legal last owner sold his product to another person
    // ? but forgot to transfer the ownership
    function createMaintenanceByOnlyMaintainer(
        uint256 _userId,
        uint256 _productId,
        string memory _description,
        string memory _location
    ) public onlyMerchants {
        uint256 currentUserId = _getUserByAddress(msg.sender).id;

        Maintenance storage newMaintenance = maintenanceList[
            maintenanceIdCounter
        ];

        newMaintenance.id = maintenanceIdCounter;
        newMaintenance.createdAt = block.timestamp;
        newMaintenance.product = _productId;

        newMaintenance.giver = MaintenanceMember(
            _userId,
            MaintenanceMemberDecision.Gave
        );
        newMaintenance.receiver = MaintenanceMember(
            currentUserId,
            MaintenanceMemberDecision.Received
        );

        ++maintenanceIdCounter;

        // reset ownership and getting product
        _resetOwnership(newMaintenance.product, _description);

        Product storage product = _getProductInStorageById(
            newMaintenance.product
        );
        require(
            product.owner.createdAt != 0,
            "This product doesn't have an owner."
        );

        User storage lastUser = _getUserById(product.owner.id);
        User storage newUser = _getUserById(_userId);
        _removeProductFromInventory(lastUser.inventory, product.id); // remove product from last user

        transferProductOwnership(product.id, _userId, ProductOwnerType.User);
        _addProductToInventory(newUser.inventory, product.id);

        updateProductState(
            newMaintenance.product,
            StateList.InService,
            0,
            _description
        );

        updateMaintenanceState(
            newMaintenance.id,
            _location,
            StateList.InService,
            _description
        );

        emit UpdatedMaintenanceMemberState(newMaintenance.id, currentUserId);
    }
}
