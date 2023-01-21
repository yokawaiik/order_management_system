import { BigNumber } from "ethers";

import OrderMember from "./OrderMember.model";

export default class Order {
  id?: BigNumber;
  mode?: BigNumber;

  buyer?: OrderMember;
  seller?: OrderMember;

  createdBy?: string;
  createdAt?: BigNumber;

  productList: Array<Object> = [];
  orderStateList: Array<Object> = [];

  constructor(
    id: BigNumber,
    mode: BigNumber,
    buyer: OrderMember,
    seller: OrderMember,
    createdBy: string,
    createdAt: BigNumber,
    productList: Array<Object>,
    orderStateList: Array<Object>
  ) {
    this.id = id;
    this.mode = mode;
    this.buyer = buyer;
    this.seller = seller;
    this.createdBy = createdBy;
    this.createdAt = createdAt;
    this.productList = productList;
    this.orderStateList = orderStateList;
  }
}
