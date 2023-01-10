import { expect } from "chai";
import { ethers } from "hardhat";
import { deployOMS } from "../fixtures/deployOMS.fixture";
import { OrderManagementSystem } from "../../typechain-types/contracts";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

describe("#TS2: simple users access control", function () {
  let orderManagementSystem: OrderManagementSystem;

  let owner: SignerWithAddress;
  let simpleUser: SignerWithAddress;
  let simpleUser2: SignerWithAddress;

  before(async function () {
    [owner, simpleUser, simpleUser2] = await ethers.getSigners();
    orderManagementSystem = await deployOMS(owner);

    await orderManagementSystem
      .connect(owner)
      .createUser(
        simpleUser.address,
        "simpleUser",
        "simpleUser",
        await orderManagementSystem.connect(owner).SIMPLE_USER_ROLE()
      );
  });

  it("Simple user can't grant roles", async function () {
    const grantRoleTx = orderManagementSystem
      .connect(simpleUser)
      .grantRole(
        await orderManagementSystem.connect(owner).ADMIN_ROLE(),
        simpleUser.address
      );

    await expect(grantRoleTx).to.be.reverted;

    const grantRoleTx2 = orderManagementSystem
      .connect(simpleUser)
      .grantRole(
        await orderManagementSystem.connect(owner).ADMIN_ROLE(),
        simpleUser2.address
      );

    await expect(grantRoleTx2).to.be.reverted;
  });

  it("User can't renounce other users' role (block his account)", async function () {
    const grantRoleTx = orderManagementSystem
      .connect(simpleUser)
      .renounceRole(
        await orderManagementSystem.connect(owner).SIMPLE_USER_ROLE(),
        owner.address
      );

    await expect(grantRoleTx).to.be.reverted;
  });

  it("User renounce role (block his account)", async function () {
    const grantRoleTx = orderManagementSystem
      .connect(simpleUser)
      .renounceRole(
        await orderManagementSystem.connect(owner).SIMPLE_USER_ROLE(),
        simpleUser.address
      );

    await expect(grantRoleTx).not.to.be.reverted;
  });
});
