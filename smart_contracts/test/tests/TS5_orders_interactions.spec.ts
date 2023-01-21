import { expect } from "chai";
import { ethers } from "hardhat";
import { deployOMS } from "../fixtures/deployOMS.fixture";
import { OrderManagementSystem } from "../../typechain-types/contracts";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { BigNumber } from "ethers/lib/ethers";
import { setupManufacturerFixture } from "../fixtures/setupManufacturer.fixture";
import { setupOrganizationFixture } from "../fixtures/setupOrganization.fixture";
import Product from "../models/Product.model";
import { produceNewProductFixture } from "../fixtures/produceNewProduct.fixture";
import { createNewOrderFixture } from "../fixtures/createNewOrder.fixture";
import OrderMemberDecision from "../enums/OrderMemberDecision.enum";
import OrderStateList from "../enums/OrderStateList.enum";
import StateList from "../enums/OrderState.enum";

describe("#TS5: orders interactions", function () {
  let owner: SignerWithAddress;
  let orderManagementSystem: OrderManagementSystem;
  let manufacturer: SignerWithAddress;
  let manufacturerOrgId: BigNumber;
  let manufacturerEmploye: SignerWithAddress;
  let simpleUser: SignerWithAddress;
  let organization: SignerWithAddress;
  let orgId: BigNumber;
  let orgEmploye: SignerWithAddress;
  let producedProducts: Array<Product> = [];

  before(async function () {
    [
      owner,
      manufacturer,
      manufacturerEmploye,
      simpleUser,
      organization,
      orgEmploye,
    ] = await ethers.getSigners();
    orderManagementSystem = await deployOMS(owner);

    await orderManagementSystem
      .connect(owner)
      .createUser(
        simpleUser.address,
        "simpleUser",
        "simpleUser",
        await orderManagementSystem.connect(owner).SIMPLE_USER_ROLE()
      );

    manufacturerOrgId = await setupManufacturerFixture(
      orderManagementSystem,
      owner,
      manufacturer,
      manufacturerEmploye
    );

    orgId = await setupOrganizationFixture(
      orderManagementSystem,
      owner,
      organization,
      orgEmploye
    );
  });

  this.beforeEach(async function () {
    producedProducts = [];
    // create products
    const price = BigNumber.from(100);
    const descriptionHash = ethers.utils.formatBytes32String("descriptionHash");
    const link = ethers.utils.formatBytes32String("link");
    const guarantee = BigNumber.from(
      (new Date().getTime() / 1000 + 60 * 4).toFixed(0)
    );
    const productType = BigNumber.from(1);
    for (let index = 0; index < 2; index++) {
      const newProduct = await produceNewProductFixture(
        orderManagementSystem,
        manufacturer,
        manufacturerOrgId,
        productType,
        price,
        descriptionHash,
        link,
        guarantee
      );
      producedProducts.push(newProduct);
    }
  });
  it("Create a new order", async function () {
    //
    const descriptionHash = ethers.utils.formatBytes32String("descriptionHash");
    const orderMode = BigNumber.from(0);
    const createOrderTx = orderManagementSystem
      .connect(organization)
      .createOrder(
        orgId,
        organization.address,
        manufacturer.address,
        descriptionHash,
        orderMode
      );

    await expect(createOrderTx).not.to.be.reverted;
  });
  it("Add product to a unconfirmed order", async function () {
    //
    const descriptionHash = ethers.utils.formatBytes32String("descriptionHash");
    const orderMode = BigNumber.from(0);

    const newOrder = await createNewOrderFixture(
      orderManagementSystem,
      orgId,
      organization,
      manufacturer,
      descriptionHash,
      orderMode
    );

    expect(newOrder).not.to.be.throw;

    // add products to order
    for (const product of producedProducts) {
      const addProductToOrderByIdTx = orderManagementSystem
        .connect(organization)
        .addProductToOrderById(orgId, newOrder.id!, product.id!);
      await expect(addProductToOrderByIdTx).not.to.be.reverted;
    }
  });
  it("Remove products from an unconfirmed order", async function () {
    //
    const descriptionHash = ethers.utils.formatBytes32String("descriptionHash");
    const orderMode = BigNumber.from(0);

    const newOrder = await createNewOrderFixture(
      orderManagementSystem,
      orgId,
      organization,
      manufacturer,
      descriptionHash,
      orderMode
    );

    expect(newOrder).not.to.be.throw;

    // add products to order
    for (const product of producedProducts) {
      const addProductToOrderByIdTx = orderManagementSystem
        .connect(organization)
        .addProductToOrderById(orgId, newOrder.id!, product.id!);
      await expect(addProductToOrderByIdTx).not.to.be.reverted;
    }

    // remove products from order
    for (const product of producedProducts) {
      const addProductToOrderByIdTx = orderManagementSystem
        .connect(organization)
        .removeProductFromOrderById(orgId, newOrder.id!, product.id!);
      await expect(addProductToOrderByIdTx).not.to.be.reverted;
    }
  });
  it("Confirm order (supplier and buyer)", async function () {
    const descriptionHash = ethers.utils.formatBytes32String("descriptionHash");
    const orderMode = BigNumber.from(0);

    const newOrder = await createNewOrderFixture(
      orderManagementSystem,
      orgId,
      organization,
      manufacturer,
      descriptionHash,
      orderMode
    );

    expect(newOrder).not.to.be.throw;

    // add products to order
    for (const product of producedProducts) {
      const addProductToOrderByIdTx = orderManagementSystem
        .connect(organization)
        .addProductToOrderById(orgId, newOrder.id!, product.id!);
      await expect(addProductToOrderByIdTx).not.to.be.reverted;
    }

    const agreement = BigNumber.from(OrderMemberDecision.Agreement);

    // approveOrder by organization
    const approveOrderByFirstOrgTx = orderManagementSystem
      .connect(organization)
      .approveOrder(orgId, newOrder.id!, agreement);

    await expect(approveOrderByFirstOrgTx).not.to.be.reverted;

    // approveOrder by manufacturer
    const approveOrderBySecondOrgTx = orderManagementSystem
      .connect(manufacturer)
      .approveOrder(manufacturerOrgId, newOrder.id!, agreement);

    await expect(approveOrderBySecondOrgTx).not.to.be.reverted;
  });
  it("Isn't possible to confirm order only supplier and finish it", async function () {
    // todo
  });
  it("Isn't possible to confirm order only buyer and finish it", async function () {
    // todo
  });
  it("Isn't possible to add products to confirmed order", async function () {
    // todo
  });
  it("Delete unconfirmed order", async function () {
    // todo
  });
  it("It isn't possible to delete confirmed order", async function () {
    // todo
  });
  it("Update order state (by seller)", async function () {
    //
    const descriptionHash = ethers.utils.formatBytes32String("descriptionHash");
    const orderMode = BigNumber.from(0);

    const newOrder = await createNewOrderFixture(
      orderManagementSystem,
      orgId,
      organization,
      manufacturer,
      descriptionHash,
      orderMode
    );

    expect(newOrder).not.to.be.throw;

    // add products to order
    for (const product of producedProducts) {
      const addProductToOrderByIdTx = orderManagementSystem
        .connect(organization)
        .addProductToOrderById(orgId, newOrder.id!, product.id!);
      await expect(addProductToOrderByIdTx).not.to.be.reverted;
    }

    // < agreement
    const agreement = BigNumber.from(OrderMemberDecision.Agreement);

    const approveOrderByFirstOrgTx = orderManagementSystem
      .connect(organization)
      .approveOrder(orgId, newOrder.id!, agreement);

    await expect(approveOrderByFirstOrgTx).not.to.be.reverted;

    const approveOrderBySecondOrgTx = orderManagementSystem
      .connect(manufacturer)
      .approveOrder(manufacturerOrgId, newOrder.id!, agreement);

    await expect(approveOrderBySecondOrgTx).not.to.be.reverted;
    // end agreement>

    // update state
    const stateDescriptionHash =
      ethers.utils.formatBytes32String("descriptionHash");

    const orderState = BigNumber.from(OrderStateList.InTransit);
    const productState = BigNumber.from(StateList.InTransit);

    const updateOrderStafteBySelerTx = orderManagementSystem
      .connect(manufacturer)
      .updateOrderStateById(
        newOrder.id!,
        stateDescriptionHash,
        orderState,
        productState
      );

    await expect(updateOrderStafteBySelerTx).not.to.be.reverted;
  });
  it("It isn't possible to update order (unconfirmed and confirmed) state by buyer", async function () {
    // todo
  });
  it("Disaprove order", async function () {
    // todo
  });
  it("Delete order (unconfirmed)", async function () {
    // todo
  });
  it("Isn't possible to delete confirmed order", async function () {
    // todo
  });
  it("Finish order", async function () {
    //
    const descriptionHash = ethers.utils.formatBytes32String("descriptionHash");
    const orderMode = BigNumber.from(0);

    const newOrder = await createNewOrderFixture(
      orderManagementSystem,
      orgId,
      organization,
      manufacturer,
      descriptionHash,
      orderMode
    );

    expect(newOrder).not.to.be.throw;

    // add products to order
    for (const product of producedProducts) {
      const addProductToOrderByIdTx = orderManagementSystem
        .connect(organization)
        .addProductToOrderById(orgId, newOrder.id!, product.id!);
      await expect(addProductToOrderByIdTx).not.to.be.reverted;
    }

    // < agreement
    const agreement = BigNumber.from(OrderMemberDecision.Agreement);

    const approveOrderByFirstOrgTx = orderManagementSystem
      .connect(organization)
      .approveOrder(orgId, newOrder.id!, agreement);

    await expect(approveOrderByFirstOrgTx).not.to.be.reverted;

    const approveOrderBySecondOrgTx = orderManagementSystem
      .connect(manufacturer)
      .approveOrder(manufacturerOrgId, newOrder.id!, agreement);

    await expect(approveOrderBySecondOrgTx).not.to.be.reverted;
    // end agreement>

    // <update state
    const stateDescriptionHash =
      ethers.utils.formatBytes32String("descriptionHash");

    const orderState = BigNumber.from(OrderStateList.InTransit);
    const productState = BigNumber.from(StateList.InTransit);

    const updateOrderStateBySelerTx = orderManagementSystem
      .connect(manufacturer)
      .updateOrderStateById(
        newOrder.id!,
        stateDescriptionHash,
        orderState,
        productState
      );

    await expect(updateOrderStateBySelerTx).not.to.be.reverted;
    // end update state>

    // < finish order
    // const finished = BigNumber.from(OrderMemberDecision.Finished);
    const finished = OrderMemberDecision.Finished;
    const finishOrderByIdBySelerTx = orderManagementSystem
      .connect(manufacturer)
      .finishOrderById(manufacturerOrgId, newOrder.id!, finished);

    await expect(finishOrderByIdBySelerTx).not.to.be.reverted;

    const finishOrderByIdByBuyerTx = orderManagementSystem
      .connect(organization)
      .finishOrderById(orgId, newOrder.id!, finished);

    await expect(finishOrderByIdByBuyerTx).not.to.be.reverted;

    // finish order>
  });
  it("Isn't possible to finish order if only one orders' member approve order", async function () {
    // todo
  });
  it("Isn't possible to transfer products if only one orders' member set 'finish' order", async function () {
    // todo
  });
  it("Approve transferring products", async function () {
    //
    const descriptionHash = ethers.utils.formatBytes32String("descriptionHash");
    const orderMode = BigNumber.from(0);

    const newOrder = await createNewOrderFixture(
      orderManagementSystem,
      orgId,
      organization,
      manufacturer,
      descriptionHash,
      orderMode
    );

    expect(newOrder).not.to.be.throw;

    // add products to order
    for (const product of producedProducts) {
      const addProductToOrderByIdTx = orderManagementSystem
        .connect(organization)
        .addProductToOrderById(orgId, newOrder.id!, product.id!);
      await expect(addProductToOrderByIdTx).not.to.be.reverted;
    }

    // < agreement
    const agreement = BigNumber.from(OrderMemberDecision.Agreement);

    const approveOrderByFirstOrgTx = orderManagementSystem
      .connect(organization)
      .approveOrder(orgId, newOrder.id!, agreement);

    await expect(approveOrderByFirstOrgTx).not.to.be.reverted;

    const approveOrderBySecondOrgTx = orderManagementSystem
      .connect(manufacturer)
      .approveOrder(manufacturerOrgId, newOrder.id!, agreement);

    await expect(approveOrderBySecondOrgTx).not.to.be.reverted;
    // end agreement>

    // <update state
    const stateDescriptionHash =
      ethers.utils.formatBytes32String("descriptionHash");

    const orderState = BigNumber.from(OrderStateList.InTransit);
    const productState = BigNumber.from(StateList.InTransit);

    const updateOrderStateBySelerTx = orderManagementSystem
      .connect(manufacturer)
      .updateOrderStateById(
        newOrder.id!,
        stateDescriptionHash,
        orderState,
        productState
      );

    await expect(updateOrderStateBySelerTx).not.to.be.reverted;
    // end update state>

    // < finish order
    // todo
    // const finished = BigNumber.from(OrderMemberDecision.Finished);
    const finished = OrderMemberDecision.Finished;
    const finishOrderByIdBySelerTx = orderManagementSystem
      .connect(manufacturer)
      .finishOrderById(manufacturerOrgId, newOrder.id!, finished);

    await expect(finishOrderByIdBySelerTx).not.to.be.reverted;

    const finishOrderByIdByBuyerTx = orderManagementSystem
      .connect(organization)
      .finishOrderById(orgId, newOrder.id!, finished);

    await expect(finishOrderByIdByBuyerTx).not.to.be.reverted;
    // finish order>

    // <transfer products
    const approveTransferringProductsByOrderIdBySelerTx = orderManagementSystem
      .connect(manufacturer)
      .approveTransferringProductsByOrderId(
        manufacturerOrgId,
        newOrder.id!,
        true
      );

    const approveTransferringProductsByOrderIdByBuyerTx = orderManagementSystem
      .connect(organization)
      .approveTransferringProductsByOrderId(orgId, newOrder.id!, true);

    await expect(approveTransferringProductsByOrderIdBySelerTx).not.to.be
      .reverted;
    // transfer products>

    // check products
    const rawManufacturer = await orderManagementSystem
      .connect(manufacturer)
      .getOrganizationById(manufacturerOrgId);
    // now supplier doesn't have products
    expect(
      rawManufacturer.inventory.map((item) => item.toNumber())
    ).not.to.deep.include.members(
      producedProducts.map((item) => item.id!.toNumber())
    );

    const rawOrg = await orderManagementSystem
      .connect(organization)
      .getOrganizationById(orgId);
    // now buyer has products

    expect(
      rawOrg.inventory.map((item) => item.toNumber())
    ).to.deep.include.members(
      producedProducts.map((item) => item.id!.toNumber())
    );
  });
  it("Isn't possible to transfer products if it's already happened", async function () {
    // todo
  });
  it("Remove order by partcipant", async function () {
    // todo
  });
  it("Isn't possible to remove order by other user", async function () {
    // todo
  });
  it("Isn't possible to approve an order by other user", async function () {
    // todo
  });
  it("An attempt to cancel an order when both parties confirm it", async function () {
    // todo
  });
});
