// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15 <0.9.0;

import "../../node_modules/@openzeppelin/contracts/utils/Counters.sol";
import "../../node_modules/@openzeppelin/contracts/access/AccessControl.sol";
import "./AccessControlManager.sol";
import "../enums/StateList.sol";
import "../enums/ProductOwnerType.sol";
import "../structures/State.sol";
import "../structures/Product.sol";
import "../structures/ProductOwner.sol";
import "../structures/Organization.sol";
import "../structures/User.sol";

contract ProductsManager is AccessControlManager {
    
    event ProductWasProduced(uint256 id, uint256 date);
    event ProductWasDeleted(uint256 id);
    event UpdatedProductState(uint256 id, uint256 date, StateList state);
    event ProductWasCompromised(uint256 id, uint256 date);
    event ProductIsRestored(uint256 id, uint256 date);
    event ProductWasTransferredFromOrganizationToOrganization(uint256 productId, ProductOwnerType ownerType, uint256 date);

    mapping(uint256 => Product) private products;
    uint256 private productIdCounter = 0; // products' certificates
    
    modifier onlyRolesMatchingToStates(StateList _state) {
        if (hasRole(MANUFACTURER_ROLE, msg.sender) != true) {
            require(
                _state != StateList.Produced || _state != StateList.Removed,
                "This states available only for manufacturers."
            );
        }
        _;
    }

    modifier onlyProductInInventory(uint256 _productId, uint256 _organizationId) {
        Organization memory org = _getOrganizationById(_organizationId);
        _getProductIndexInInventory(_productId, org.inventory);
        _;
    }

    // ? info: find product by id
    function getProductById(uint256 productId) public view returns (Product memory) {
        return _getProductInStorageById(productId);
    }

    function getProductState(uint256 _productId) public view returns (State memory) {
        Product memory product = _getProductInStorageById(_productId);
        return product.stateHistory[product.stateHistory.length - 1];
    }

    function checkLegalityProductToTransferOrSale(uint256 _productId) public view returns (bool) {
        Product storage product = _getProductInStorageById(_productId);

        // State storage lastState = product.stateHistory[
        //     product.stateHistory.length - 1
        // ];

        State memory lastState = getProductState(_productId);
        ProductOwner storage currentOwner = product.ownershipHistory[
            product.ownershipHistory.length - 1
        ];

        require(
            lastState.state != StateList.WasDestroyed ||
                lastState.state != StateList.Removed,
            "Product was removed by manufacturer."
        );

        require(
            currentOwner.ownerType != ProductOwnerType.User,
            "Product has owner user now."
        );

        require(
            lastState.state != StateList.WasCompromised,
            "This product was compromised."
        );

        return true;
    }

    function _getProductIndexInInventory(uint256 _productId, uint256[] memory _userInventory) internal pure 
    returns (uint256 index)
    {
        for (uint256 i = 0; i < _userInventory.length; i++) {
            if (_productId == _userInventory[i]) return i;
        }

        revert("Such product didn't find in inventory.");
    }

    function produceNewProduct(uint256 _organizationId, uint256 _productType, uint256 _price, 
    string memory _description, bytes32 _specification, uint256 expiresAt)
    public onlyOrganizationEmploye(_organizationId) onlyRole(MANUFACTURER_ROLE)
    {
        // uint256 currentTimestamp = block.timestamp;

        require(
            expiresAt > block.timestamp,
            "Guarantee expires at must be more then current time."
        );

        User storage manufacturer = _getUserByAddress(msg.sender);

        uint256 newProductId = productIdCounter;
        Product storage newProduct = products[newProductId];

        ++productIdCounter; // increase counter

        products[newProductId] = newProduct;

        newProduct.id = newProductId;
        newProduct.productType = _productType;

        newProduct.createdBy = msg.sender;
        newProduct.createdAt = block.timestamp;
        newProduct.createdAt = expiresAt;
        newProduct.specification = _specification;

        State storage pushedState = newProduct.stateHistory.push();

        pushedState.state = StateList.Produced;
        pushedState.date = block.timestamp;
        pushedState.price = _price;
        pushedState.createdBy = msg.sender;
        pushedState.description = _description;

        ProductOwner memory currentOwner = ProductOwner(
            manufacturer.userAddress,
            block.timestamp,
            ProductOwnerType.Manufacturer
        );
        newProduct.ownershipHistory.push(currentOwner);

        uint256[] storage orgInventory = _getOrganizationInventoryById(
            _organizationId
        );

        _addProductToInventory(newProductId, orgInventory);

        emit ProductWasProduced(newProductId, block.timestamp);
    }

    // ? info: if produced product was a mistake
    function removeProduct(uint256 _organizationId, uint256 _productId, string memory _description)
    public onlyOrganizationEmploye(_organizationId) onlyRole(MANUFACTURER_ROLE)
    {
        Product storage product = _getProductInStorageById(_productId);

        uint256 currentTimestamp = block.timestamp;

        require(
            product.createdAt + TIME_TO_CORRECT_MISTAKE < block.timestamp,
            "Operation is not allowed because time for remove is out."
        );

        require(
            product.stateHistory[product.stateHistory.length - 1].state !=
                StateList.Removed,
            "Product was removed."
        );

        State storage newState = product.stateHistory.push();

        newState.state = StateList.Removed;
        newState.date = currentTimestamp;
        newState.price = product.lastPrice;
        newState.createdBy = msg.sender;
        newState.description = _description;

        uint256[] storage orgInventory = _getOrganizationInventoryById(
            _organizationId
        );

        _removeProductFromInventory(_productId, orgInventory);

        emit ProductWasDeleted(_productId);
    }

    function restoreProduct(uint256 _organizationId, uint256 _productId, string memory _description)
    public onlyRole(MANUFACTURER_ROLE) onlyProductInInventory(_productId, _organizationId)
    {
        Product storage product = _getProductInStorageById(_productId);
        State memory lastState = getProductState(_productId);

        uint256 currentTimestamp = block.timestamp;

        require(
            product.expiresAt > currentTimestamp,
            "Product isn't maintenance because guarantee is expired."
        );

        require(
            lastState.state != StateList.WasDestroyed ||
                lastState.state != StateList.Removed,
            "Repairing available only for existing products."
        );

        State storage newState = product.stateHistory.push();

        // product.lastState = newState;
        newState.state = StateList.WasRestored;
        newState.date = currentTimestamp;
        newState.price = product.lastPrice;
        newState.createdBy = msg.sender;
        newState.description = _description;

        emit ProductIsRestored(_productId, currentTimestamp);
    }

    function unlockProductOwnership(uint256 _organizationId, uint256 _productId, string memory _description) 
    public onlyRole(MANUFACTURER_ROLE) {
        Product storage product = _getProductInStorageById(_productId);

        uint256 currentTimestamp = block.timestamp;

        require(
            product
                .ownershipHistory[product.ownershipHistory.length - 1]
                .ownerType == ProductOwnerType.UserLeft,
            "Unlock ownership available only if last user agrees to left ownership."
        );

        State storage newState = product.stateHistory.push();

        newState.date = currentTimestamp;
        newState.price = product.lastPrice;
        newState.createdBy = msg.sender;
        newState.description = _description;
        newState.state = StateList.Unlocked;

        _resetOwnership(_organizationId, _productId, _description);
    }

    // ? info : if legal last owner left ownership
    function _resetOwnership(uint256 _organizationId, uint256 _productId, string memory _description) internal {
        Product storage product = _getProductInStorageById(_productId);

        updateProductState(
            _organizationId,
            _productId,
            StateList.OwnerWasChanged,
            0,
            _description
        );

        ProductOwner storage lastOwner = product.ownershipHistory[
            product.ownershipHistory.length - 1
        ];
        lastOwner.ownerType = ProductOwnerType.UserLeft;

        emit ProductWasTransferredFromOrganizationToOrganization(
            _productId,
            lastOwner.ownerType,
            block.timestamp
        );
    }

    function _getProductInStorageById(uint256 _productId) internal view returns (Product storage) {
        Product storage product = products[_productId];

        require(product.createdAt != 0, "Product with such an id wasn't find.");
        return product;
    }

    // ? info: sell roduct and transfer ownership
    function sellProduct(uint256 _organizationId, uint256 _productId, address _newOwner, string memory _description)
    public onlyOrganizationSeller(_organizationId) onlyProductInInventory(_productId, _organizationId) returns (bool)
    {
        uint256 currentTimestamp = block.timestamp;
        Product storage product = _getProductInStorageById(_productId);
        State memory lastState = getProductState(_productId);
        ProductOwner memory lastOwner = product.ownershipHistory[
            product.ownershipHistory.length - 1
        ];
        checkLegalityProductToTransferOrSale(_productId);

        State storage newState = product.stateHistory.push();
        // sale attempt but the product someone compromised because product with such an id has an owner

        if (
            lastState.state == StateList.Sold &&
            lastOwner.ownerType == ProductOwnerType.User
        ) {
            newState.state = StateList.WasCompromised;
            emit ProductWasCompromised(_productId, currentTimestamp);
        }
        // success transfer
        else {
            ProductOwner memory newOrder = ProductOwner(
                _newOwner,
                currentTimestamp,
                ProductOwnerType.User
            );
            newState.state = StateList.Sold;
            product.ownershipHistory.push(newOrder);
        }

        newState.date = currentTimestamp;
        newState.price = product.lastPrice;
        newState.createdBy = msg.sender;
        newState.description = _description;

        if (newState.state == StateList.WasCompromised) {
            return false;
        } else {
            return true;
        }
    }

    function transferProductOrganizationToOrganization(uint256 _productId, uint256 _organizationFromId, uint256 _organizationIdTo)
    public onlyOrganizationSeller(_organizationFromId) onlyProductInInventory(_productId, _organizationFromId)
    {
        uint256 currentTimestamp = block.timestamp;
        Product storage product = _getProductInStorageById(_productId);

        Organization storage orgFrom = _getOrganizationById(
            _organizationFromId
        );
        Organization storage orgTo = _getOrganizationById(_organizationIdTo);

        ProductOwner memory newProductOwner = ProductOwner(
            address(0),
            currentTimestamp,
            ProductOwnerType.Seller
        );

        product.ownershipHistory.push(newProductOwner);
        _removeProductFromInventory(_productId, orgFrom.inventory);
        _addProductToInventory(_productId, orgTo.inventory);

        emit ProductWasTransferredFromOrganizationToOrganization(
            _productId,
            ProductOwnerType.Seller,
            currentTimestamp
        );
    }

    // ? info: add new state to product history
    function updateProductState(uint256 _organizationId, uint256 _productId, 
    StateList _state, uint256 _price,string memory _description)
    public onlyOrganizationSeller(_organizationId) onlyRolesMatchingToStates(_state)
    onlyProductInInventory(_productId, _organizationId) {
        _updateProductState(_productId, _state, _price, _description);

        emit UpdatedProductState(_productId, block.timestamp, _state);
    }

    function _updateProductState(uint256 _productId, StateList _state, uint256 _price, string memory _description) internal {
        Product storage product = _getProductInStorageById(_productId);

        State storage newState = product.stateHistory.push();

        newState.state = _state;
        newState.date = block.timestamp;
        newState.createdBy = msg.sender;
        newState.description = _description;

        if (_state == StateList.PriceWasChanged) {
            newState.price = _price;
        } else {
            newState.price = product.lastPrice;
        }

        product.stateHistory.push(newState);
    }
}
