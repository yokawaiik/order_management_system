import { expect } from "chai";
import { ethers } from "hardhat";
import { deployOMS } from "../fixtures/deployOMS.fixture";
import { OrderManagementSystem } from "../../typechain-types/contracts";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { BigNumber } from "ethers/lib/ethers";
import { setupManufacturerFixture } from "../fixtures/setupManufacturer.fixture";
import { setupOrganizationFixture } from "../fixtures/setupOrganization.fixture";

describe("#TS4: product controlling", function () {
  let owner: SignerWithAddress;
  let orderManagementSystem: OrderManagementSystem;

  let manufacturer: SignerWithAddress;
  let manufacturerOrgId: BigNumber;
  let manufacturerEmploye: SignerWithAddress;
  let simpleUser: SignerWithAddress;

  let organization: SignerWithAddress;
  let orgId: BigNumber;
  let orgEmploye: SignerWithAddress;

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

  it("Check if a new manufacturer was Registered", async function () {
    expect(manufacturerOrgId).not.to.be.null;
  });

  it("Manufacturer produce products", async function () {
    const price = BigNumber.from(100);
    const descriptionHash = ethers.utils.formatBytes32String("descriptionHash");
    const specificationHash =
      ethers.utils.formatBytes32String("specificationHash");
    const guarantee = (new Date().getTime() / 1000 + 60).toFixed(0);
    const productType = BigNumber.from(1);

    const produceNewProductTX = orderManagementSystem
      .connect(manufacturer)
      .produceNewProduct(
        manufacturerOrgId,
        productType,
        price,
        descriptionHash,
        specificationHash,
        guarantee
      );

    await expect(produceNewProductTX).not.to.be.reverted;

    const newProductId = (await produceNewProductTX).value;

    const productValue = await orderManagementSystem
      .connect(manufacturer)
      .getProductById(newProductId);

    expect(productValue.id).to.be.eq(newProductId);
  });

  it("Other roles can't produce products", async function () {
    const price = BigNumber.from(100);
    const descriptionHash = ethers.utils.formatBytes32String("descriptionHash");
    const specificationHash =
      ethers.utils.formatBytes32String("specificationHash");
    const guarantee = BigNumber.from(
      (new Date().getTime() / 1000 + 60).toFixed(0)
    );
    const productType = BigNumber.from(1);

    const produceNewProductTx = orderManagementSystem
      .connect(simpleUser)
      .produceNewProduct(
        manufacturerOrgId,
        productType,
        price,
        descriptionHash,
        specificationHash,
        guarantee
      );

    await expect(produceNewProductTx).to.be.revertedWith(
      "You aren't an employe of this organization."
    );
  });

  it("Manufacturer's employees can't produce products", async function () {
    const price = BigNumber.from(100);
    const descriptionHash = ethers.utils.formatBytes32String("descriptionHash");
    const specificationHash =
      ethers.utils.formatBytes32String("specificationHash");
    const guarantee = BigNumber.from(
      (new Date().getTime() / 1000 + 60).toFixed(0)
    );
    const productType = BigNumber.from(1);

    const produceNewProductTx = orderManagementSystem
      .connect(manufacturerEmploye)
      .produceNewProduct(
        manufacturerOrgId,
        productType,
        price,
        descriptionHash,
        specificationHash,
        guarantee
      );

    await expect(produceNewProductTx).to.be.reverted;
  });

  it("Update product state by only organization's seller", async function () {
    const price = BigNumber.from(100);
    const descriptionHash = ethers.utils.formatBytes32String("descriptionHash");
    const specificationHash =
      ethers.utils.formatBytes32String("specificationHash");
    const guarantee = BigNumber.from(
      (new Date().getTime() / 1000 + 60).toFixed(0)
    );
    const productType = BigNumber.from(1);

    const produceNewProductTx = orderManagementSystem
      .connect(manufacturer)
      .produceNewProduct(
        manufacturerOrgId,
        productType,
        price,
        descriptionHash,
        specificationHash,
        guarantee
      );

    await expect(produceNewProductTx).not.to.be.reverted;

    const productId = (await produceNewProductTx).value;

    const newProductState = 3;
    const updateProductStateTx = orderManagementSystem
      .connect(manufacturer)
      .updateProductState(
        manufacturerOrgId,
        productId,
        newProductState,
        0,
        descriptionHash
      );

    await expect(updateProductStateTx).not.to.be.reverted;

    const updatedProductState = await orderManagementSystem
      .connect(manufacturer)
      .getProductById(productId);

    expect(
      updatedProductState.stateHistory[
        updatedProductState.stateHistory.length - 1
      ].state
    ).to.be.equal(newProductState);
  });

  it("Transfer product from organization to organization", async function () {
    const price = BigNumber.from(100);
    const descriptionHash = ethers.utils.formatBytes32String("descriptionHash");
    const specificationHash =
      ethers.utils.formatBytes32String("specificationHash");
    const guarantee = BigNumber.from(
      (new Date().getTime() / 1000 + 60).toFixed(0)
    );
    const productType = BigNumber.from(1);

    const produceNewProductTx = orderManagementSystem
      .connect(manufacturer)
      .produceNewProduct(
        manufacturerOrgId,
        productType,
        price,
        descriptionHash,
        specificationHash,
        guarantee
      );

    await expect(produceNewProductTx).not.to.be.reverted;

    const productId = await orderManagementSystem
      .connect(manufacturer)
      .getLastProductId();

    const transferProductOrganizationToOrganizationTx =
      await orderManagementSystem
        .connect(manufacturer)
        .transferProductOrganizationToOrganization(
          productId,
          manufacturerOrgId,
          orgId
        );

    expect(transferProductOrganizationToOrganizationTx).not.to.be.reverted;

    const organizationObject = await orderManagementSystem
      .connect(organization)
      .getOrganizationById(orgId);

    expect(
      organizationObject.inventory.map((item) => item.toNumber())
    ).to.be.include(productId.toNumber());
  });

  it("Attempt updating product state if organization hasn't it in inventory", async function () {
    //  todo
  });

  it("Unlock product", async function () {
    //  todo
  });

  it("Success restore product by manufacturer (product guarantee)", async function () {
    //  todo
  });

  it("Unsuccess restore product by manufacturer (product guarantee is expired)", async function () {
    //  todo
  });

  it("Not a manufacturer can't restore product", async function () {
    //  todo
  });

  it("Unlock product ownership by manufacturer", async function () {
    //  todo
  });

  it("Sell product to seller", async function () {
    //  todo
  });
});
