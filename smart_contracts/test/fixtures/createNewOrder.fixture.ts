import { expect } from "chai";

import { OrderManagementSystem } from "../../typechain-types/contracts";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { BigNumber } from "ethers";
import Product from "../models/Product.model";
import Order from "../models/Order.model";
import OrderMember from "../models/OrderMember.model";

const createNewOrderFixture = async function (
  orderManagementSystem: OrderManagementSystem,
  userOrgId: BigNumber,
  buyer: SignerWithAddress,
  supplier: SignerWithAddress,
  descriptionHash: string,
  orderMode: BigNumber
): Promise<Order> {
  const createOrderTx = orderManagementSystem
    .connect(buyer)
    .createOrder(
      userOrgId,
      buyer.address,
      supplier.address,
      descriptionHash,
      orderMode
    );

  await expect(createOrderTx).not.to.be.reverted;

  const oderId = BigNumber.from(
    (await orderManagementSystem.connect(buyer).getOrderIdCounter()).sub(1)
  );

  const rawOrder = await orderManagementSystem
    .connect(buyer)
    .getOrderById(userOrgId, oderId);

  const order = new Order(
    rawOrder.id,
    BigNumber.from(rawOrder.mode),
    new OrderMember(
      rawOrder.buyer.organizationId,
      rawOrder.buyer.userAddress,
      rawOrder.buyer.transferred,
      BigNumber.from(rawOrder.buyer.decision)
    ),
    new OrderMember(
      rawOrder.seller.organizationId,
      rawOrder.seller.userAddress,
      rawOrder.seller.transferred,
      BigNumber.from(rawOrder.seller.decision)
    ),
    rawOrder.createdBy,
    BigNumber.from(rawOrder.createdBy),
    rawOrder.productList.map((item) => ({
      id: item.id,
      transferred: item.transferred,
    })),
    rawOrder.orderStateList.map((item) => ({
      state: item.state,
      descriptionHash: item.descriptionHash,
      createdBy: item.createdBy,
      createdAt: item.createdAt,
    }))
  );

  return order;
};

export { createNewOrderFixture };
