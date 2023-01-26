import { OrderManagementSystem } from "../../typechain-types/contracts";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { BigNumber } from "ethers";
import { expect } from "chai";

const setupOrganizationFixture = async function (
  orderManagementSystem: OrderManagementSystem,
  owner: SignerWithAddress,
  adminOrganization: SignerWithAddress,
  employe: SignerWithAddress
): Promise<BigNumber> {
  let orgId: BigNumber;

  await orderManagementSystem
    .connect(owner)
    .createUser(
      adminOrganization.address,
      "adminOrganization",
      "adminOrganization",
      await orderManagementSystem.connect(owner).ADMIN_ORGANIZATION_ROLE()
    );

  await orderManagementSystem
    .connect(owner)
    .grantRole(
      await orderManagementSystem.connect(owner).SELLER_ROLE(),
      adminOrganization.address
    );

  await orderManagementSystem
    .connect(adminOrganization)
    .createOrganization("Organization");

  orgId = (await orderManagementSystem
    .connect(adminOrganization)
    .getOrganizationIdCounter()).sub(1);

  // console.log("orgId: " + orgId);

  await orderManagementSystem
    .connect(owner)
    .createUser(
      employe.address,
      "employe",
      "employe",
      await orderManagementSystem.connect(owner).SELLER_ROLE()
    );

  await orderManagementSystem
    .connect(adminOrganization)
    .addEmployeToOrganization(orgId, employe.address, 2);

  return orgId;
};

export { setupOrganizationFixture };
