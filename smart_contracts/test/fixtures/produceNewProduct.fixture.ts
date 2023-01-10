import { expect } from "chai";

import { OrderManagementSystem } from "../../typechain-types/contracts";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { BigNumber } from "ethers";

import Product from "../models/Product.model";

const produceNewProductFixture = async function (
  orderManagementSystem: OrderManagementSystem,
  manufacturer: SignerWithAddress,
  manufacturerOrgId: BigNumber,
  productType: BigNumber,
  price: BigNumber,
  description: string,
  link: string,
  guarantee: BigNumber
): Promise<Product> {
  const produceNewProductTx = orderManagementSystem
    .connect(manufacturer)
    .produceNewProduct(
      manufacturerOrgId,
      productType,
      price,
      description,
      link,
      guarantee
    );

  await expect(produceNewProductTx).not.to.be.reverted;

  const newProductId = await orderManagementSystem
    .connect(manufacturer)
    .getLastProductId();
  expect(newProductId).not.to.be.empty;

  const productValue = await orderManagementSystem
    .connect(manufacturer)
    .getProductById(newProductId);

  expect(productValue.id).to.be.eq(newProductId);

  const product = new Product(
    productValue.id,
    productValue.productType,
    productValue.createdBy,
    productValue.createdAt,
    productValue.expiresAt,
    productValue.specification
  );

  product.stateHistory = productValue.stateHistory.map((item: any) => ({
    createdBy: item.createdBy,
    date: item.date,
    description: item.description,
    price: item.price,
    createstatedBy: item.state,
  }));

  product.ownershipHistory = productValue.ownershipHistory.map((item: any) => ({
    createdAt: item.createdAt,
    owner: item.owner,
    ownerType: item.ownerType,
  }));

  return product;
};

export { produceNewProductFixture };
