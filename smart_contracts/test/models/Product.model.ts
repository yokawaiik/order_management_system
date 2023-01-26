import { BigNumber } from "ethers";

export default class Product {
  id?: BigNumber ;
  productType?: BigNumber;
  createdBy?: string;
  createdAt?: BigNumber;
  expiresAt?: BigNumber;
  ownershipHistory: Array<Object> = [];
  stateHistory: Array<Object> = [];

  specification?: string;

  isBlockedFromOrdering: boolean = false;

  constructor(
    id: BigNumber,
    productType: BigNumber,
    createdBy: string,
    createdAt: BigNumber,
    expiresAt: BigNumber,
    specification: string
  ) {
    this.id = id;
    this.productType = productType;
    this.createdBy = createdBy;
    this.createdAt = createdAt;
    this.expiresAt = expiresAt;
    this.specification = specification;
  }
}
