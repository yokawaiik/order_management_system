// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15 <0.9.0;

import './AccessControlManager.sol';

import "../enums/OrderMemberDecision.sol";

import '../structures/Order.sol';


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
        ParticipantDecision decision
    );

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

        uint256 currentUserId = findUserIdByAddress(msg.sender);

        require(
            order.buyer.userId == currentUserId ||
                order.seller.userId == currentUserId,
            "Change order possible only for participant."
        );
        _;
    }

    modifier onlyUnconfirmedOrders(uint256 _orderId) {
        Order memory order = _getOrderById(_orderId);

        require(
            (order.buyer.decision != ParticipantDecision.Disagreement ||
                order.seller.decision != ParticipantDecision.Disagreement) ||
                (order.seller.decision != ParticipantDecision.Deleted ||
                    order.buyer.decision != ParticipantDecision.Deleted),
            "This order was denied by buyer or seller."
        );

        require(
            order.buyer.decision != ParticipantDecision.Agreement &&
                order.seller.decision != ParticipantDecision.Agreement,
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

    function createOrder(address _buyerAddress, address _sellerAddress)
        public
        onlyMerchants
    {
        require(
            _buyerAddress == msg.sender || _sellerAddress == msg.sender,
            "Only agent can be buyer or seller."
        );

        uint256 _buyerId = findUserIdByAddress(_buyerAddress);
        uint256 _sellerId = findUserIdByAddress(_sellerAddress);

        Order storage newOrder = orders[productIdCounter];
        newOrder.id = productIdCounter;
        ++productIdCounter; // increase a counter
        newOrder.createdAt = block.timestamp;
        newOrder.buyer = Participant(
            _buyerId,
            false,
            ParticipantDecision.Unhandled
        );
        newOrder.seller = Participant(
            _sellerId,
            false,
            ParticipantDecision.Unhandled
        );

        emit CreatedOrder(newOrder.id, newOrder.createdAt, _sellerId, _buyerId);
    }

    function addProductToOrder(uint256 _orderId, uint256 _productId)
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

    function removeProductFromOrder(uint256 _orderId, uint256 _productId)
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

        _removeProductFromOrderProductList(orderProductList, _productId);
    }

    function _removeProductFromOrderProductList(
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

    function approveTransferingProductsInOrder(uint256 _orderId)
        public
        onlyMerchants
        onlyOrderParticipants(_orderId)
        onlyUntransferredProductsInOrders(_orderId)
    {
        Order storage order = orders[_orderId];

        uint256 currentUserId = findUserIdByAddress(msg.sender);

        if (order.seller.userId == currentUserId) {
            order.seller.transferred = true;
        } else {
            order.buyer.transferred = true;
        }

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
                    // add
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

    function setOrderState(uint256 _orderId, ParticipantDecision _decision)
        public
        onlyMerchants
        onlyOrderParticipants(_orderId)
        onlyUnconfirmedOrders(_orderId)
    {
        Order memory order = _getOrderById(_orderId);

        uint256 currentUserId = findUserIdByAddress(msg.sender);

        if (order.buyer.userId == currentUserId) {
            order.buyer.decision = _decision;
        } else {
            order.seller.decision = _decision;
        }

        emit ParticipantSetOrderStatus(_orderId, currentUserId, _decision);
    }
}
