import { OrderManagementSystem } from "../../typechain-types/contracts";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { BigNumber } from "ethers";

const setupManufacturerFixture = async function (
  orderManagementSystem: OrderManagementSystem,
  owner: SignerWithAddress,
  manufacturer: SignerWithAddress,
  manufacturerEmploye: SignerWithAddress
) {
  let manufacturerOrgId: BigNumber;

  await orderManagementSystem
    .connect(owner)
    .createUser(
      manufacturer.address,
      "manufacturer",
      "manufacturer",
      await orderManagementSystem.connect(owner).ADMIN_ORGANIZATION_ROLE()
    );

  await orderManagementSystem
    .connect(owner)
    .grantRole(
      await orderManagementSystem.connect(owner).SELLER_ROLE(),
      manufacturer.address
    );

  await orderManagementSystem
    .connect(owner)
    .grantRole(
      await orderManagementSystem.connect(owner).MANUFACTURER_ROLE(),
      manufacturer.address
    );

  await orderManagementSystem
    .connect(manufacturer)
    .createOrganization("manufacturerOrg");

  manufacturerOrgId = (await orderManagementSystem
    .connect(manufacturer)
    .getOrganizationIdCounter()).sub(1);

  // console.log("manufacturerOrgId: " + manufacturerOrgId);

  await orderManagementSystem
    .connect(owner)
    .createUser(
      manufacturerEmploye.address,
      "manufacturerEmploye",
      "manufacturerEmploye",
      await orderManagementSystem.connect(owner).SELLER_ROLE()
    );

  await orderManagementSystem
    .connect(manufacturer)
    .addEmployeToOrganization(
      manufacturerOrgId,
      manufacturerEmploye.address,
      2
    );

  return manufacturerOrgId;
};

export { setupManufacturerFixture };
