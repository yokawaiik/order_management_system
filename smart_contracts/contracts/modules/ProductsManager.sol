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

contract ProductsManager is AccessControlManager {

    event ProductWasProduced(uint256 id, uint256 date);
    event ProductWasDeleted(uint256 id);
    event UpdatedProductState(uint256 id, uint256 date, StateList state);
    event ProductWasCompromised(uint256 id, uint256 date);
    event ProductIsRestored(uint256 id, uint256 date);
    event TransferedOwnership(
        uint256 productId,
        ProductOwnerType ownerType,
        uint256 date
    );

    mapping(uint256 => Product) private products;
    // certificates of products
    uint256 private productIdCounter = 0;

    // ? info: find product by id
    function findProductById(uint256 productId)
        public
        view
        returns (Product memory)
    {
        return _findProductInStorageById(productId);
    }

    function getProductState(uint256 _productId)
        public
        view
        returns (State memory)
    {
        Product memory product = _findProductInStorageById(_productId);
        return product.lastState;
    }

    modifier onlyRolesMatchingToStates(StateList _state) {
        if (hasRole(MANUFACTURER_ROLE, msg.sender) != true) {
            require(
                _state != StateList.Produced ||
                    _state != StateList.Removed ||
                    _state != StateList.WasDestroyed,
                "This states available only for manufacturers."
            );
        }
        _;
    }

    modifier onlyProductInInventory(uint256 _productId) {
        uint256 userId = findUserIdByAddress(msg.sender);
        User memory currentUser = findUserById(userId);
        _getProductIndexInUserInventory(_productId, currentUser.inventory);
        _;
    }

    function checkLegalityProductToTransferOrSale(uint256 _productId)
        public
        view
        returns (bool)
    {
        Product storage product = _findProductInStorageById(_productId);

        require(
            product.lastState.state != StateList.WasDestroyed ||
                product.lastState.state != StateList.Removed,
            "Product was removed by manufacturer."
        );

        require(
            product.owner.ownerType != ProductOwnerType.User,
            "Product has owner user now."
        );

        require(
            product.lastState.state != StateList.WasCompromised,
            "This product was compromised."
        );

        return true;
    }

    function _getProductIndexInUserInventory(
        uint256 _productId,
        uint256[] memory _userInventory
    ) internal pure returns (uint256 index) {
        for (uint256 i = 0; i < _userInventory.length; i++) {
            if (_productId == _userInventory[i]) return i;
        }

        revert("Such product didn't find in inventory.");
    }

    function exportProducts()
        external
        view
        onlyRole(OWNER_ROLE)
        returns (Product[] memory)
    {
        Product[] memory memoryArray = new Product[](productIdCounter);

        if (productIdCounter == 0) {
            return memoryArray;
        }

        for (uint256 i = 0; i < productIdCounter; i++) {
            memoryArray[i] = products[i];
        }

        return memoryArray;
    }

    function produceProduct(
        uint256 _productType,
        uint256 _price,
        string memory _description,
        bytes32 _specification,
        uint256 expiresAt
    ) public onlyRole(MANUFACTURER_ROLE) {
        uint256 currentTimestamp = block.timestamp;

        require(
            expiresAt > currentTimestamp,
            "Guarantee expires at must be more then current time."
        );

        uint256 currentUserId = findUserByAddress(msg.sender).id;

        uint256 newProductId = productIdCounter;
        Product storage newProduct = products[newProductId];

        ++productIdCounter; // increase counter

        products[newProductId] = newProduct;

        newProduct.id = newProductId;
        newProduct.productType = _productType;
        newProduct.owner = ProductOwner(
            currentUserId,
            currentTimestamp,
            ProductOwnerType.Manufacturer
        );

        newProduct.createdBy = msg.sender;
        newProduct.createdAt = currentTimestamp;

        newProduct.createdAt = expiresAt;

        newProduct.lastPrice = _price;
        newProduct.specification = _specification;

        State storage pushedState = newProduct.stateHistory.push();

        pushedState.state = StateList.Produced;
        pushedState.date = currentTimestamp;
        pushedState.price = _price;
        pushedState.createdBy = msg.sender;
        pushedState.description = _description;

        newProduct.lastState = pushedState;

        uint256 foundUserId = findUserIdByAddress(msg.sender);

        newProduct.ownershipHistory.push(newProduct.owner);

        _addProductToInventory(newProductId, foundUserId);
        emit ProductWasProduced(newProductId, currentTimestamp);
    }

    function _addProductToInventory(uint256 _productId, uint256 _userId)
        internal
    {
        users[_userId].inventory.push(_productId);
    }

    // ? info: if produced product was a mistake
    function removeProduct(uint256 _productId, string memory _description)
        public
        onlyRole(MANUFACTURER_ROLE)
    {
        Product storage product = _findProductInStorageById(_productId);

        uint256 currentTimestamp = block.timestamp;

        require(
            product.createdAt + TIME_TO_CORRECT_MISTAKE < block.timestamp,
            "Operation not allowed because time for remove is out."
        );

        require(
            product.lastState.state != StateList.Removed,
            "Product was removed."
        );

        State storage newState = product.stateHistory.push();

        product.lastState = newState;
        newState.state = StateList.Removed;
        newState.date = currentTimestamp;
        newState.price = product.lastPrice;
        newState.createdBy = msg.sender;
        newState.description = _description;

        uint256 foundUserId = findUserIdByAddress(msg.sender);

        _removeProductFromInventory(_productId, foundUserId);
        emit ProductWasDeleted(_productId);
    }

    function _removeProductFromInventory(uint256 _productId, uint256 _userId)
        internal
        onlyProductInInventory(_productId)
    {
        uint256[] storage userInventory = users[_userId].inventory;

        for (uint256 i = 0; i < userInventory.length; i++) {
            if (userInventory[i] == _productId) {
                for (uint256 j = i; j < userInventory.length - 1; j++) {
                    userInventory[j] = userInventory[j + 1];
                }
                userInventory.pop();
                break;
            }
        }
    }

    function restoreProduct(uint256 _productId, string memory _description)
        public
        onlyRole(MANUFACTURER_ROLE)
        onlyProductInInventory(_productId)
    {
        Product storage product = _findProductInStorageById(_productId);

        uint256 currentTimestamp = block.timestamp;

        require(
            product.expiresAt > currentTimestamp,
            "Product isn't maintenance because guarantee is expired."
        );

        require(
            product.lastState.state != StateList.WasDestroyed ||
                product.lastState.state != StateList.Removed,
            "Repairing available only for existing products."
        );

        State storage newState = product.stateHistory.push();

        product.lastState = newState;
        newState.state = StateList.WasRestored;
        newState.date = currentTimestamp;
        newState.price = product.lastPrice;
        newState.createdBy = msg.sender;
        newState.description = _description;

        emit ProductIsRestored(_productId, currentTimestamp);
    }

    function unlockProductOwnership(
        uint256 _productId,
        string memory _description
    ) public onlyRole(MANUFACTURER_ROLE) {
        Product storage product = _findProductInStorageById(_productId);

        uint256 currentTimestamp = block.timestamp;

        require(
            product.owner.ownerType == ProductOwnerType.UserLeft,
            "Unlock ownership available only if last user agrees to left ownership."
        );

        State storage newState = product.stateHistory.push();

        product.lastState = newState;
        newState.state = StateList.WasRestored;
        newState.date = currentTimestamp;
        newState.price = product.lastPrice;
        newState.createdBy = msg.sender;
        newState.description = _description;
    }

    // ? info : if legal last owner left ownership
    function _resetOwnership(uint256 _productId, string memory _description)
        internal
    {
        Product storage product = _findProductInStorageById(_productId);

        addNewStateToProduct(
            _productId,
            StateList.OwnerWasChanged,
            0,
            _description
        );

        ProductOwner storage lastOwner = product.ownershipHistory[
            product.ownershipHistory.length - 1
        ];
        lastOwner.ownerType = ProductOwnerType.UserLeft;
        product.owner = lastOwner;

        emit TransferedOwnership(
            _productId,
            ProductOwnerType.UserLeft,
            block.timestamp
        );
    }

    function _findProductInStorageById(uint256 _productId)
        internal
        view
        returns (Product storage)
    {
        Product storage product = products[_productId];

        require(product.createdAt != 0, "Product with such an id wasn't find.");
        return product;
    }

    // ? info: sell roduct and transfer ownership
    function sellProduct(
        uint256 _productId,
        uint256 _newOwnerId,
        string memory _description
    ) public onlyMerchants onlyProductInInventory(_productId) returns (bool) {
        uint256 currentTimestamp = block.timestamp;
        Product storage product = _findProductInStorageById(_productId);
        checkLegalityProductToTransferOrSale(_productId);

        State storage newState = product.stateHistory.push();
        // sale attempt but the product someone compromised because product with such an id has an owner
        if (
            product.lastState.state == StateList.Sold &&
            product.owner.ownerType == ProductOwnerType.User
        ) {
            product.lastState.state = StateList.WasCompromised;
            newState.state = StateList.WasCompromised;
            emit ProductWasCompromised(_productId, currentTimestamp);
        }
        // success transfer
        else {
            product.owner = ProductOwner(
                _newOwnerId,
                currentTimestamp,
                ProductOwnerType.User
            );
            product.lastState.state = StateList.Sold;
            newState.state = StateList.Sold;
            product.ownershipHistory.push(product.owner);
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

    // ? info: add shipping event
    function addShippingEvent(
        StateList _state,
        uint256 _productId,
        string memory _description
    )
        public
        onlyTransporters
        onlyRolesMatchingToStates(_state)
        onlyProductInInventory(_productId)
    {
        Product storage product = _findProductInStorageById(_productId);

        uint256 currentTimestamp = block.timestamp;

        State storage productStateHistory = product.stateHistory.push();

        productStateHistory.createdBy = msg.sender;
        productStateHistory.date = currentTimestamp;
        productStateHistory.description = _description;
        productStateHistory.price = product.lastPrice;
        productStateHistory.state = _state;

        emit UpdatedProductState(_productId, currentTimestamp, _state);
    }

    function transferProductOwnership(
        uint256 _productId,
        uint256 _userIdTo,
        ProductOwnerType _ownerType
    ) public onlyMerchants onlyProductInInventory(_productId) {
        uint256 currentTimestamp = block.timestamp;
        Product storage product = _findProductInStorageById(_productId);

        ProductOwner memory currentProductOwner = product.owner;

        uint256 currentUserId = findUserIdByAddress(msg.sender);

        require(
            currentProductOwner.createdAt != 0 &&
                product.owner.id == currentUserId,
            "Transfer ownership available can only owner."
        );

        require(
            product.lastState.state != StateList.Removed ||
                product.lastState.state != StateList.WasDestroyed,
            "Can not transfer ownerhip for products what was removed or destroyed."
        );

        require(
            product.owner.ownerType == ProductOwnerType.User &&
                product.owner.id == currentUserId,
            "Transfer product ownership possible from only owner."
        );

        require(
            _ownerType != ProductOwnerType.Manufacturer ||
                _ownerType != ProductOwnerType.None,
            "Can not set such an owner type. It requires special access right."
        );

        ProductOwner memory newProductOwner = ProductOwner(
            _userIdTo,
            currentTimestamp,
            _ownerType
        );

        product.owner = newProductOwner;
        product.ownershipHistory.push(newProductOwner);

        emit TransferedOwnership(_productId, _ownerType, currentTimestamp);
    }

    // ? info: add new state to product history
    function addNewStateToProduct(
        uint256 _productId,
        StateList _state,
        uint256 _price,
        string memory _description
    )
        public
        onlyMerchants
        onlyRolesMatchingToStates(_state)
        onlyProductInInventory(_productId)
    {
        Product storage product = _findProductInStorageById(_productId);

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

        product.lastState = newState;
        product.stateHistory.push(newState);

        emit UpdatedProductState(_productId, newState.date, newState.state);
    }
}
