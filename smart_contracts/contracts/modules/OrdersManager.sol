// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15 <0.9.0;

import "./AccessControlManager.sol";
import "./ProductsManager.sol";

import "../enums/OrderMemberDecision.sol";
import "../enums/StateList.sol";
import "../enums/OrderMode.sol";
import "../structures/Order.sol";
import "../structures/OrderState.sol";

import {StringLibrary} from "../libraries/StringLibrary.sol";

contract OrdersManager is AccessControlManager, ProductsManager {

    event CreatedOrder(
        uint256 orderId,
        uint256 createdAt,
        uint256 seller,
        uint256 buyer
    );
    
    event ProductWasAddedToOrder(uint256 productId, uint256 orderId);

    event OrderStateWasUpdated(
        uint256 orderId,
        StateList _state,
        address _user,
        string _description
    );

    event UserApprovedTransferring(uint256 _id, address _userAddress, bool _decision);
    event ProductsInOrderWasTransferred(uint256 _id, address _userAddress, bool _decision);



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
        onlyMerchants
        returns (Order storage)
    {
        Order storage order = orders[_orderId];
        require(order.createdAt != 0, "Such an order wasn't registered.");
        return order;
    }

    function getOrderById(uint256 _orderId)
        public
        view
        onlyMerchants
        returns (Order memory)
    {
        return _getOrderById(_orderId);
    }

    function exportOrders()
        external
        view
        onlyRole(OWNER_ROLE)
        returns (Order[] memory)
    {
        Order[] memory memoryArray = new Order[](productIdCounter);

        for (uint256 i = 0; i < productIdCounter; i++) {
            memoryArray[i] = orders[i];
        }

        return memoryArray;
    }

    modifier onlyOrderParticipants(uint256 _orderId) {
        Order memory order = _getOrderById(_orderId);

        uint256 currentUserId = _getUserByAddress(msg.sender).id;

        require(
            order.buyer.userId == currentUserId ||
                order.seller.userId == currentUserId,
            "Change order is possible only for participant."
        );
        _;
    }

    // todo: check this logic
    modifier onlyUnconfirmedOrders(uint256 _orderId) {
        Order memory order = _getOrderById(_orderId);

        require(
            (order.buyer.decision == OrderMemberDecision.Disagreement ||
                order.seller.decision == OrderMemberDecision.Disagreement) ||
                (order.seller.decision == OrderMemberDecision.Deleted ||
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
        address _buyerAddress,
        address _sellerAddress,
        string memory _description,
        string memory _location,
        OrderMode _orderMode
    ) public onlyMerchants {
        require(
            _buyerAddress == msg.sender || _sellerAddress == msg.sender,
            "Only agent can be buyer or seller."
        );

        uint256 _buyerId = _getUserByAddress(_buyerAddress).id;
        uint256 _sellerId = _getUserByAddress(_sellerAddress).id;

        Order storage newOrder = orders[productIdCounter];
        newOrder.id = productIdCounter;
        newOrder.mode = _orderMode;
        ++productIdCounter; // increase a counter
        newOrder.createdAt = block.timestamp;
        newOrder.buyer = OrderMember(
            _buyerId,
            false,
            OrderMemberDecision.Unhandled
        );
        newOrder.seller = OrderMember(
            _sellerId,
            false,
            OrderMemberDecision.Unhandled
        );

        // fill first OrderState
        OrderState storage currentOrderState = newOrder.orderStateList.push();
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
        currentOrderState.user = msg.sender;
        currentOrderState.state = StateList.Unhandled;

        emit CreatedOrder(newOrder.id, newOrder.createdAt, _sellerId, _buyerId);
    }

    function removeOrderById(uint256 _orderId)
        public
        onlyMerchants
        onlyUnconfirmedOrders(_orderId)
        onlyOrderParticipants(_orderId)
    {
        delete orders[_orderId];
    }

    function addProductToOrderById(uint256 _orderId, uint256 _productId)
        public
        onlyMerchants
        onlyUnconfirmedOrders(_orderId)
        onlyOrderParticipants(_orderId)
    {
        ProductInOrder[] storage orderProductList = orders[_orderId]
            .productList;

        // check if product with such an id was added in order
        require(
            _checkProductInOrderProductList(orderProductList, _productId) !=
                true,
            "Product with such an id was added in order."
        );

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

    function removeProductFromOrderById(uint256 _orderId, uint256 _productId)
        public
        onlyMerchants
    {
        ProductInOrder[] storage orderProductList = orders[_orderId]
            .productList;

        // check if product with such an id was added in order
        require(
            _checkProductInOrderProductList(orderProductList, _productId) ==
                true,
            "Product with such an id was added in order."
        );

        _removeProductFromOrderByIdProductList(orderProductList, _productId);
    }

    function _removeProductFromOrderByIdProductList(
        ProductInOrder[] storage _array,
        uint256 _productId
    ) internal {
        for (uint256 i = 0; i < _array.length; i++) {
            if (_array[i].id == _productId) {
                for (uint256 j = i; j < _array.length - 1; j++) {
                    _array[j] = _array[j + 1];
                }
                _array.pop();
                break;
            }
        }
    }


    // method approve for everybody because regular user also approve
    function approveTransferringProductsByOrderId(
        uint256 _orderId,
        bool _decision
    )
        public
        onlyOrderParticipants(_orderId)
        onlyUntransferredProductsInOrders(_orderId)
    {
        Order storage order = orders[_orderId];

        uint256 currentUserId = _getUserByAddress(msg.sender).id;

        if (order.seller.userId == currentUserId) {
            order.seller.transferred = _decision; // true or false
        } else {
            order.buyer.transferred = _decision; // true or false
        }

        // if both Merchants approved then transfer
        if (
            order.seller.transferred == true && order.buyer.transferred == true
        ) {
            _transferProductsInOrder(
                order.productList,
                order.seller.userId,
                order.buyer.userId
            );
            emit ProductsInOrderWasTransferred(order.id, msg.sender, _decision);
        } 
        // just emit event
        else {
            emit UserApprovedTransferring(order.id, msg.sender, _decision);
        }

    }

    function _transferProductsInOrder(
        ProductInOrder[] storage _productList,
        uint256 _sellerId,
        uint256 _buyerId
    ) internal onlyMerchants {
        User storage seller = _getUserById(_sellerId);
        User storage buyer = _getUserById(_buyerId);

        for (uint256 i = 0; i < _productList.length; i++) {
            for (uint256 j = 0; j < seller.inventory.length; j++) {
                if (_productList[i].id == seller.inventory[j]) {
                    _addProductToInventory(buyer.inventory, _productList[i].id);
                    _removeProductFromInventory(
                        seller.inventory,
                        _productList[i].id
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
        StateList _orderState
    ) {

        require(
            _orderState != StateList.Unhandled,
            "These operations are forbidden: Unhandled."
        );

        Order memory order = _getOrderById(_orderId);

        if (order.mode == OrderMode.Default) {
            require(
                _orderState == StateList.InTransit ||
                    _orderState == StateList.InWarehouse ||
                    _orderState == StateList.OnSale ||
                    _orderState == StateList.Sold ||
                    _orderState == StateList.Removed,
                "Available only maintenance states: InTransit, InWarehouse, OnSale, Sold, Removed."
            );

            require(
                _orderState == StateList.Received &&
                    _orderState ==
                    order.orderStateList[order.orderStateList.length - 1].state,
                "Operation 'Received' is forbidden because order has already received."
            );

        }
        // Maintenance
        else {
            require(
                _orderState == StateList.InService ||
                    _orderState == StateList.WasFinished ||
                    _orderState == StateList.WasDeny,
                "Available only maintenance states: InService, WasFinished, WasDeny."
            );

            // if order was got
            require(
            order
                .orderStateList[
                    order.orderStateList.length - 1
                ]
                .state != StateList.WasGotByOwner,
            "Unavailable state, because order has already been got by owner."
        );
        }

        _;
    }

    function updateOrderStateById(
        uint256 _orderId,
        string memory _description,
        string memory _location,
        StateList _orderState,
        OrderMemberDecision _orderMemberDecision
    )
        public
        onlyMerchants
        onlyOrderParticipants(_orderId)
        onlyUnconfirmedOrders(_orderId)
        strictOrderModeCheckAndStateList(_orderId, _orderState)
    {

        Order storage order = _getOrderById(_orderId);


        uint256 currentUserId = _getUserByAddress(msg.sender).id;

        if (order.buyer.userId == currentUserId) {
            order.buyer.decision = _orderMemberDecision;
        } else {
            order.seller.decision = _orderMemberDecision;
        }

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

        currentOrderState.user = msg.sender;

        currentOrderState.state = _orderState;
        


        ProductInOrder[] storage productsList = order.productList;

        // todo: checkhow it works
        for (uint256 i = 0; i < productsList.length; i++) {
            updateProductState(productsList[i].id, _orderState, 0, _description);
        }

        emit OrderStateWasUpdated(
            _orderId,
            _orderState,
            msg.sender,
            _description
        );
    }

}
