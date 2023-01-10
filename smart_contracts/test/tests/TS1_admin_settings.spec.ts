import { expect } from "chai";
import { ethers } from "hardhat";
import {deployOMS} from "../fixtures/deployOMS.fixture";
import { OrderManagementSystem } from "../../typechain-types/contracts";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

describe("#TS1: administrators logics", function () {
  let orderManagementSystem: OrderManagementSystem;
  let owner: SignerWithAddress;
  let newAdmin: SignerWithAddress;

  before(async function () {
    [owner, newAdmin] = await ethers.getSigners();
    orderManagementSystem = await deployOMS(owner);

    await orderManagementSystem
      .connect(owner)
      .createUser(
        newAdmin.address,
        "newAdmin",
        "newAdmin",
        await orderManagementSystem.connect(owner).ADMIN_ROLE()
      );

    await orderManagementSystem
      .connect(owner)
      .grantRole(
        await orderManagementSystem.connect(owner).ADMIN_ROLE(),
        newAdmin.address
      );
  });

  it("New user was added like an admin.", async function () {
    const newAdminUser = orderManagementSystem
      .connect(owner)
      .getUserByAddress(newAdmin.address);

    await expect(newAdminUser).not.to.be.revertedWith(
      "User with such an address wasn't find."
    );

    expect((await newAdminUser).role).to.equal(
      await orderManagementSystem.connect(newAdmin).ADMIN_ROLE()
    );
  });

  it("New admin register a new user and revoke him.", async function () {
    const newManufacturer = ethers.Wallet.createRandom();

    const newUserTx = orderManagementSystem
      .connect(newAdmin)
      .createUser(
        newManufacturer.address,
        "newManufacturer",
        "newManufacturer",
        await orderManagementSystem.connect(newAdmin).MANUFACTURER_ROLE()
      );

    await expect(newUserTx).not.to.be.reverted;

    const revokeAdminTx = orderManagementSystem
      .connect(newAdmin)
      .revokeRole(
        await orderManagementSystem.connect(newAdmin).MANUFACTURER_ROLE(),
        owner.address
      );

    await expect(revokeAdminTx).not.to.be.reverted;
  });

  it("New admin can't delete the main admin.", async function () {
    const revokeAdminTx = orderManagementSystem
      .connect(newAdmin)
      .revokeRole(
        await orderManagementSystem.connect(newAdmin).ADMIN_ROLE(),
        owner.address
      );

    await expect(revokeAdminTx).to.be.reverted;
  });

});
