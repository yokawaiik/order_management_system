import { expect } from "chai";
import { ethers } from "hardhat";
import {deployOMS} from "../fixtures/deployOMS.fixture";
import { OrderManagementSystem } from "../../typechain-types/contracts";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { BigNumber } from "ethers/lib/ethers";

describe("#TS3: testing the logic of interaction with organizations", function () {
  let orderManagementSystem: OrderManagementSystem;
  let owner: SignerWithAddress;
  let adminOrganization: SignerWithAddress;
  let employe: SignerWithAddress;
  const orgTitle = "OrgTitle";
  let orgId: BigNumber;

  before(async function () {
    [owner, adminOrganization, employe] = await ethers.getSigners();
    orderManagementSystem = await deployOMS(owner);

    await orderManagementSystem
      .connect(owner)
      .createUser(
        adminOrganization.address,
        "adminOrganization",
        "adminOrganization",
        await orderManagementSystem.connect(owner).ADMIN_ROLE()
      );

    await orderManagementSystem
      .connect(owner)
      .grantRole(
        await orderManagementSystem.connect(owner).ADMIN_ORGANIZATION_ROLE(),
        adminOrganization.address
      );
  });

  it("Create an organization", async function () {
    const createOrganizationTx = await orderManagementSystem
      .connect(adminOrganization)
      .createOrganization(orgTitle);

    await expect(orderManagementSystem).not.to.be.reverted;
    orgId = createOrganizationTx.value;
  });

  it("Add a new employee to organization", async function () {
    const createUserTx = orderManagementSystem
      .connect(owner)
      .createUser(
        employe.address,
        "newEmploye",
        "newEmploye",
        await orderManagementSystem.connect(owner).SELLER_ROLE()
      );
    await expect(orderManagementSystem).not.to.be.reverted;

    const role = 1; // 0 None, 1 Admin, 2 Employe

    const addEmployeToOrganizationTx = orderManagementSystem
      .connect(adminOrganization)
      .addEmployeToOrganization(orgId, employe.address, role);

    await expect(addEmployeToOrganizationTx).not.to.be.reverted;

    const employeUser = await orderManagementSystem
      .connect(adminOrganization)
      .getUserByAddress(employe.address);

    expect(employeUser.organizationMember.role).to.be.equal(role);
  });

  it("Change employe role", async function () {
    const newRole = 0; // 0 None, 1 Admin, 2 Employe
    const addEmployeToOrganizationTx = orderManagementSystem
      .connect(adminOrganization)
      .addEmployeToOrganization(orgId, employe.address, newRole);

    const employeWithChangedRole = await orderManagementSystem
      .connect(adminOrganization)
      .getUserByAddress(employe.address);

    expect(employeWithChangedRole.organizationMember.role).to.be.equal(newRole);
  });

  it("Remove employe from an organization", async function () {
    const deleteEmployeFromOrganizationTx = await orderManagementSystem
      .connect(adminOrganization)
      .deleteEmployeFromOrganization(orgId, employe.address);

    await expect(orderManagementSystem).not.to.be.reverted;

    const deletedEmploye = await orderManagementSystem
      .connect(adminOrganization)
      .getUserByAddress(employe.address);

    expect(deletedEmploye.organizationMember.organizationId).to.be.equal(0);
    expect(deletedEmploye.organizationMember.role).to.be.equal(0);
    expect(deletedEmploye.organizationMember.addedAt).to.be.equal(0);

    const deletedEmployeHasSellerRole = await orderManagementSystem
      .connect(adminOrganization)
      .hasRole(
        await orderManagementSystem.connect(adminOrganization).SELLER_ROLE(),
        employe.address
      );
    expect(deletedEmployeHasSellerRole).to.be.equal(false);
  });

  it("Another organization admin (from another organization) tries to change role", async function () {
    // todo
  });

  it("Simple employe tries to change role", async function () {
    // todo
  });

  it("Simple employe tries to delete user", async function () {
    // todo
  });
});
