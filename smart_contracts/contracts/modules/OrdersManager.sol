// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15 <0.9.0;

import "./AccessControlManager.sol";

import "../enums/OrderMemberDecision.sol";
import "../enums/OrderStateList.sol";

import "../structures/Order.sol";
import "../structures/OrderState.sol";

import {StringLibrary} from "../libraries/StringLibrary.sol";

contract OrdersManager is AccessControlManager {
    event CreatedOrder(
        uint256 orderId,
        uint256 createdAt,
        uint256 seller,
        uint256 buyer
    );
    event ProductWasAddedToOrder(uint256 productId, uint256 orderId);
    event ParticipantSetOrderStatus(
        uint256 orderId,
        uint256 deletedBy,
        OrderMemberDecision decision
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

    modifier onlyUnconfirmedOrders(uint256 _orderId) {
        Order memory order = _getOrderById(_orderId);

        require(
            (order.buyer.decision != OrderMemberDecision.Disagreement ||
                order.seller.decision != OrderMemberDecision.Disagreement) ||
                (order.seller.decision != OrderMemberDecision.Deleted ||
                    order.buyer.decision != OrderMemberDecision.Deleted),
            "This order was denied by buyer or seller."
        );

        require(
            order.buyer.decision != OrderMemberDecision.Agreement &&
                order.seller.decision != OrderMemberDecision.Agreement,
            "This action available only for unconfirmed orders."
        );
        _;
    }

    modifier onlyUntransferredProductsInOrders(uint256 _orderId) {
        Order memory order = _getOrderById(_orderId);

        require(
            order.buyer.transferred != true && order.seller.transferred != true,
            "Can't transfer because products were transferred."
        );
        _;
    }

    function createOrder(
        address _buyerAddress,
        address _sellerAddress,
        string memory _description,
        string memory _location
    ) public onlyMerchants {
        require(
            _buyerAddress == msg.sender || _sellerAddress == msg.sender,
            "Only agent can be buyer or seller."
        );

        uint256 _buyerId = _getUserByAddress(_buyerAddress).id;
        uint256 _sellerId = _getUserByAddress(_sellerAddress).id;

        Order storage newOrder = orders[productIdCounter];
        newOrder.id = productIdCounter;
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
        currentOrderState.state = OrderStateList.Unhandled;

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
    ) internal onlyMerchants {
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

    function approveTransferringProductsByOrderId(
        uint256 _orderId,
        bool _decision
    )
        public
        onlyMerchants
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

    function updateOrderStateById(
        uint256 _orderId,
        string memory _description,
        string memory _location,
        OrderStateList _orderState,
        OrderMemberDecision _orderMemberDecision
    )
        public
        onlyMerchants
        onlyOrderParticipants(_orderId)
        onlyUnconfirmedOrders(_orderId)
    {
        require(
            _orderState != OrderStateList.Unhandled,
            "These operations are forbidden: Unhandled."
        );

        Order storage order = _getOrderById(_orderId);

        require(
            _orderState == OrderStateList.Received &&
                _orderState ==
                order.orderStateList[order.orderStateList.length - 1].state,
            "Operation 'Received' is forbidden because order has already received."
        );

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

        emit ParticipantSetOrderStatus(
            _orderId,
            currentUserId,
            _orderMemberDecision
        );
    }
}
