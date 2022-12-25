// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15 <0.9.0;

import "./AccessControlManager.sol";
import "./ProductsManager.sol";

import "../enums/OrderMemberDecision.sol";
import "../enums/StateList.sol";
import "../enums/OrderStateList.sol";
import "../enums/OrderMode.sol";
import "../structures/Order.sol";
import "../structures/State.sol";

import {StringLibrary} from "../libraries/StringLibrary.sol";

contract OrdersManager is AccessControlManager, ProductsManager {
    event CreatedOrder(
        uint256 orderId,
        uint256 createdAt,
        address seller,
        address buyer
    );

    event ProductWasAddedToOrder(uint256 productId, uint256 orderId);

    event OrderStateWasUpdated(
        uint256 orderId,
        OrderStateList _state,
        address _user,
        string _description
    );

    event DecisionWasMadeOnOrder(
        uint256 _orderId,
        address _userAddress,
        OrderMemberDecision _memberDecision
    );

    event UserApprovedTransferring(
        uint256 _orderId,
        address _userAddress,
        bool _decision
    );
    event ProductsInOrderWasTransferred(
        uint256 _orderId,
        address _userAddress,
        bool _decision
    );

    constructor() {
        _grantRole(OWNER_ROLE, msg.sender);
        _setRoleAdmin(DEFAULT_ADMIN_ROLE, ADMIN_ROLE);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    mapping(uint256 => Order) orders;
    uint256 private productIdCounter = 0;

    function _getOrderById(uint256 _orderId)
        internal
        view
        returns (Order storage)
    {
        Order storage order = orders[_orderId];
        require(order.createdAt != 0, "Such an order wasn't registered.");
        return order;
    }

    function getOrderById(uint256 _organizationId, uint256 _orderId)
        public
        view
        onlyOrganizationEmploye(_organizationId)
        returns (Order memory)
    {
        return _getOrderById(_orderId);
    }

    function exportOrder(uint256 _orderId)
        external
        view
        onlyRole(OWNER_ROLE)
        returns (Order memory)
    {
        return _getOrderById(_orderId);
    }

    // organization participant users
    modifier onlyOrderParticipants(uint256 _orderId) {
        Order memory order = _getOrderById(_orderId);

        User memory user = _getUserByAddress(msg.sender);

        require(
            user.organizationMember.organizationId ==
                order.buyer.organizationId ||
                user.organizationMember.organizationId ==
                order.seller.organizationId,
            "This action is possible only for orders' organization participants."
        );
        _;
    }

    // todo: check this logic
    modifier onlyUnconfirmedOrders(uint256 _orderId) {
        Order memory order = _getOrderById(_orderId);

        require(
            !(order.buyer.decision == OrderMemberDecision.Disagreement ||
                order.seller.decision == OrderMemberDecision.Disagreement) ||
                !(order.seller.decision == OrderMemberDecision.Deleted ||
                    order.buyer.decision == OrderMemberDecision.Deleted),
            "This order was denied by buyer or seller."
        );

        require(
            order.buyer.decision == OrderMemberDecision.Agreement &&
                order.seller.decision == OrderMemberDecision.Agreement,
            "This action available only for unconfirmed orders."
        );
        _;
    }
    modifier onlyConfirmedOrders(uint256 _orderId) {
        Order memory order = _getOrderById(_orderId);

        require(
            order.buyer.decision == OrderMemberDecision.Agreement &&
                order.seller.decision == OrderMemberDecision.Agreement,
            "This action available only for unconfirmed orders."
        );
        _;
    }

    function isOrderFinished(uint256 _orderId) public view returns (bool) {
        Order memory order = _getOrderById(_orderId);

        if (
            order.buyer.decision == OrderMemberDecision.Finished &&
            order.seller.decision == OrderMemberDecision.Finished
        ) {
            return true;
        } else {
            return false;
        }
    }

    // todo: check this logic
    modifier onlyUntransferredProductsInOrders(uint256 _orderId) {
        Order memory order = _getOrderById(_orderId);

        require(
            order.buyer.transferred == true && order.seller.transferred == true,
            "Can't transfer because products were transferred."
        );
        _;
    }

    function createOrder(
        uint256 _organizationId,
        address _buyerAddress,
        address _sellerAddress,
        string memory _description,
        string memory _location,
        OrderMode _orderMode
    ) public onlyOrganizationEmploye(_organizationId) {
        uint256 timestamp = block.timestamp;

        // check if exists
        User storage buyer = _getUserByAddress(_buyerAddress);
        User storage seller = _getUserByAddress(_sellerAddress);

        Order storage newOrder = orders[productIdCounter];

        newOrder.id = productIdCounter;
        newOrder.mode = _orderMode;
        ++productIdCounter; // increase a counter
        newOrder.createdAt = timestamp;

        newOrder.buyer = OrderMember(
            buyer.organizationMember.organizationId,
            _buyerAddress,
            false,
            OrderMemberDecision.Unhandled
        );

        newOrder.seller = OrderMember(
            seller.organizationMember.organizationId,
            _sellerAddress,
            false,
            OrderMemberDecision.Unhandled
        );

        // fill first OrderState
        OrderState memory currentOrderState = newOrder.orderStateList.push();

        // add new state
        if (!StringLibrary.compareTwoStrings(_description, "")) {
            currentOrderState.description = "Order was created.";
        } else {
            currentOrderState.description = _description;
        }

        if (!StringLibrary.compareTwoStrings(_location, "")) {
            currentOrderState.location = "Undefined";
        } else {
            currentOrderState.location = _location;
        }
        currentOrderState.state = OrderStateList.Unhandled;
        currentOrderState.createdBy = msg.sender;
        currentOrderState.createdAt = timestamp;
        // ---

        emit CreatedOrder(
            newOrder.id,
            newOrder.createdAt,
            _sellerAddress,
            _buyerAddress
        );
    }

    modifier onlyUnblockedProduct(uint256 _productId) {
        Product memory product = _getProductInStorageById(_productId);

        string memory message = string(
            abi.encodePacked(
                "This operation unavailable, because product with id ",
                _productId,
                " is blocked from ordering."
            )
        );

        require(product.isBlockedFromOrdering == true, message);

        _;
    }

    function _productLock(uint256 _productId, bool _lockState) internal {
        Product storage product = _getProductInStorageById(_productId);
        product.isBlockedFromOrdering = _lockState;
    }

    function removeOrderById(uint256 _organizationId, uint256 _orderId)
        public
        onlyOrganizationEmploye(_organizationId)
        onlyUnconfirmedOrders(_orderId)
        onlyOrderParticipants(_orderId)
    {
        Order memory order = _getOrderById(_orderId);

        // unblocked products in order
        for (uint256 i = 0; i < order.productList.length; i++) {
            _productLock(order.productList[i].id, false);
        }

        delete orders[_orderId];
    }

    function addProductToOrderById(
        uint256 _organizationId,
        uint256 _orderId,
        uint256 _productId
    )
        public
        onlyOrganizationEmploye(_organizationId)
        onlyUnconfirmedOrders(_orderId)
        onlyOrderParticipants(_orderId)
        onlyUnblockedProduct(_productId)
    {
        ProductInOrder[] storage orderProductList = _getOrderById(_orderId)
            .productList;

        Order storage order = _getOrderById(_orderId);
        Organization storage orgSeller = _getOrganizationById(
            order.seller.organizationId
        );

     
        require(
            _checkProductInInventory(_productId, orgSeller.inventory) == true,
            "Seller's organization doesn't have this product."
        );

        require(
            _checkProductInOrderProductList(orderProductList, _productId) !=
                true,
            "Product with such an id was added in order."
        );

        _productLock(_productId, true);

        orderProductList.push(ProductInOrder(_productId, false));
        emit ProductWasAddedToOrder(_productId, _orderId);
    }

    function _checkProductInOrderProductList(
        ProductInOrder[] memory array,
        uint256 _productId
    ) internal pure returns (bool) {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i].id == _productId) {
                return true;
            }
        }
        return false;
    }

    function removeProductFromOrderById(
        uint256 _organizationId,
        uint256 _orderId,
        uint256 _productId
    )
        public
        onlyUnconfirmedOrders(_orderId)
        onlyOrderParticipants(_orderId)
        onlyOrganizationEmploye(_organizationId)
    {
        ProductInOrder[] storage orderProductList = orders[_orderId]
            .productList;

        _productLock(_productId, false);

        _removeProductsFromOrder(orderProductList, _productId);
    }

    function _removeProductsFromOrder(
        ProductInOrder[] storage _productList,
        uint256 _productId
    ) internal {
        // check if product with such an id was added in order

        require(
            _checkProductInOrderProductList(_productList, _productId) == true,
            "Product with such an id was added in order."
        );

        for (uint256 i = 0; i < _productList.length; i++) {
            if (_productList[i].id == _productId) {
                for (uint256 j = i; j < _productList.length - 1; j++) {
                    _productList[j] = _productList[j + 1];
                }
                _productList.pop();
                break;
            }
        }
    }

    function approveTransferringProductsByOrderId(
        uint256 _organizationId,
        uint256 _orderId,
        bool _transferDecision
    )
        public
        onlyOrganizationEmploye(_organizationId)
        onlyOrderParticipants(_orderId)
        onlyUntransferredProductsInOrders(_orderId)
    {
        require(
            isOrderFinished(_orderId) == false,
            "This order hasn't been finished yet."
        );

        Order storage order = orders[_orderId];

        User memory currentUser = _getUserByAddress(msg.sender);

        // check if organization exists
        _getOrganizationById(_organizationId);

        if (
            order.seller.organizationId ==
            currentUser.organizationMember.organizationId
        ) {
            order.seller.transferred = _transferDecision;
        } else {
            order.buyer.transferred = _transferDecision;
        }

        // if both Merchants approved transferring
        if (
            order.seller.transferred == true && order.buyer.transferred == true
        ) {
            _transferProductsInOrder(
                order.productList,
                order.seller.userAddress,
                order.buyer.userAddress
            );
            emit ProductsInOrderWasTransferred(
                order.id,
                msg.sender,
                _transferDecision
            );
        }
        // just emit event
        else {
            emit UserApprovedTransferring(
                order.id,
                msg.sender,
                _transferDecision
            );
        }
    }

    function _transferProductsInOrder(
        ProductInOrder[] storage _productList,
        address _sellerAddress,
        address _buyerAddress
    ) internal {
        User storage seller = _getUserByAddress(_sellerAddress);
        User storage buyer = _getUserByAddress(_buyerAddress);

        Organization storage orgSeller = _getOrganizationById(
            seller.organizationMember.organizationId
        );

        Organization storage orgBuyer = _getOrganizationById(
            buyer.organizationMember.organizationId
        );

        for (uint256 i = 0; i < _productList.length; i++) {
            _productLock(_productList[i].id, false);
        }

        for (uint256 i = 0; i < _productList.length; i++) {
            for (uint256 j = 0; j < orgSeller.inventory.length; j++) {
                if (_productList[i].id == orgSeller.inventory[j]) {
                    _addProductToInventory(
                        _productList[i].id,
                        orgBuyer.inventory
                    );
                    _removeProductFromInventory(
                        _productList[i].id,
                        orgSeller.inventory
                    );

                    _productList[i].transferred = true;
                }
            }
        }
    }

    // only strict correspondence of order functions
    // todo: check this logic
    modifier strictOrderModeCheckAndStateList(
        uint256 _orderId,
        OrderStateList _orderState
    ) {
        require(
            _orderState != OrderStateList.Unhandled,
            "These operations are forbidden: Unhandled."
        );

        Order memory order = _getOrderById(_orderId);

        if (order.mode == OrderMode.Default) {
            require(
                _orderState == OrderStateList.InTransit ||
                    _orderState == OrderStateList.InWarehouse ||
                    _orderState == OrderStateList.WasFinished ||
                    _orderState == OrderStateList.WasStopped ||
                    _orderState == OrderStateList.WasDeny ||
                    _orderState == OrderStateList.Removed ||
                    // Maintenance
                    _orderState != OrderStateList.InService,
                "Available only order states: InTransit, WasStopped, InWarehouse, WasFinished, WasDeny, Removed."
            );
        }

        // check if order has already been done
        require(
            (_orderState == OrderStateList.WasFinished ||
                _orderState == OrderStateList.WasDeny ||
                _orderState == OrderStateList.Removed) &&
                _orderState ==
                order.orderStateList[order.orderStateList.length - 1].state,
            "Operation 'Received' is forbidden because order has already received."
        );
        _;
    }

    function approveOrder(
        uint256 _organizationId,
        uint256 _orderId,
        OrderMemberDecision _orderMemberDecision
    )
        public
        onlyOrganizationEmploye(_organizationId)
        onlyOrderParticipants(_orderId)
        onlyUnconfirmedOrders(_orderId)
    {
        User storage currentUser = _getUserByAddress(msg.sender);
        Order storage order = _getOrderById(_orderId);

        if (
            currentUser.organizationMember.organizationId ==
            order.buyer.organizationId
        ) {
            order.buyer.decision = _orderMemberDecision;
        } else if (
            currentUser.organizationMember.organizationId ==
            order.seller.organizationId
        ) {
            order.seller.decision = _orderMemberDecision;
        }

        if (
            order.seller.decision == OrderMemberDecision.Agreement &&
            order.buyer.decision == OrderMemberDecision.Agreement
        ) {
            // it's blocked products in order
            for (uint256 i = 0; i < order.productList.length; i++) {
                _productLock(order.productList[i].id, true);
            }
        } else {
            emit DecisionWasMadeOnOrder(
                _orderId,
                msg.sender,
                _orderMemberDecision
            );
        }
    }

    function finishOrderById(
        uint256 _organizationId,
        uint256 _orderId,
        OrderMemberDecision _orderMemberDecision
    )
        public
        onlyOrganizationEmploye(_organizationId)
        onlyOrderParticipants(_orderId)
        onlyConfirmedOrders(_orderId)
    {
        User storage currentUser = _getUserByAddress(msg.sender);
        Order storage order = _getOrderById(_orderId);

        require(
            _orderMemberDecision == OrderMemberDecision.Waiting ||
                _orderMemberDecision == OrderMemberDecision.Finished,
            "For this action are available the following decisions: Waiting, Finished."
        );

        require(
            order.buyer.decision != OrderMemberDecision.Finished &&
                order.seller.decision != OrderMemberDecision.Finished,
            "This order has already been finished."
        );

        if (
            currentUser.organizationMember.organizationId ==
            order.buyer.organizationId
        ) {
            order.buyer.decision = _orderMemberDecision;
        } else if (
            currentUser.organizationMember.organizationId ==
            order.seller.organizationId
        ) {
            order.seller.decision = _orderMemberDecision;
        }
    }

    function updateOrderStateById(
        uint256 _organizationId,
        uint256 _orderId,
        string memory _description,
        string memory _location,
        OrderStateList _orderState,
        StateList _productsStates
    )
        public
        onlyOrganizationEmploye(_organizationId)
        onlyOrderParticipants(_orderId)
        onlyConfirmedOrders(_orderId)
        strictOrderModeCheckAndStateList(_orderId, _orderState)
    {
        Order storage order = _getOrderById(_orderId);

        // fill first OrderState
        OrderState storage currentOrderState = order.orderStateList.push();
        if (!StringLibrary.compareTwoStrings(_description, "")) {
            currentOrderState.description = "No description.";
        } else {
            currentOrderState.description = _description;
        }
        if (!StringLibrary.compareTwoStrings(_location, "")) {
            currentOrderState.location = "Undefined";
        } else {
            currentOrderState.location = _location;
        }

        currentOrderState.createdBy = msg.sender;
        currentOrderState.createdAt = block.timestamp;
        currentOrderState.state = _orderState;

        ProductInOrder[] storage productsList = order.productList;

        for (uint256 i = 0; i < productsList.length; i++) {
            _updateProductState(
                productsList[i].id,
                _productsStates,
                0,
                _description
            );
        }

        emit OrderStateWasUpdated(
            _orderId,
            _orderState,
            msg.sender,
            _description
        );
    }
}
