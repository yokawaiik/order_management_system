import { ethers } from "hardhat";

async function main() {
  console.log(`----------------- DEPLOY SCRIPT START -----------------`);

  const [deployer] = await ethers.getSigners();
  console.log(`Deploying contracts with the account: ${deployer.address}.`);

  // deploy the library
  const StringLibrary = await ethers.getContractFactory("StringLibrary");
  const stringLibrary = await StringLibrary.deploy();
  await stringLibrary.deployed();

  const OrderManagementSystemUpgradable = await ethers.getContractFactory(
    "OrderManagementSystemUpgradable",
    {
      signer: deployer,
      libraries: {
        StringLibrary: stringLibrary.address,
      },
    }
  );
  // deploy contract
  const orderManagementSystemUpgradable =
    await OrderManagementSystemUpgradable.deploy();

  console.log(
    `OrderManagementSystemUpgradable contract was deployed to ${orderManagementSystemUpgradable.address} address.`
  );
  console.log(`----------------- DEPLOY SCRIPT END -----------------`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
