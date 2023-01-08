import hre, { ethers } from "hardhat";

export default async (deployer: any) => {
  const StringLibrary = await ethers.getContractFactory("StringLibrary");
  
  const stringLibrary = await StringLibrary.deploy();
  await stringLibrary.deployed();

  const OrderManagementSystem = await ethers.getContractFactory(
    "OrderManagementSystem",
    {
      signer: deployer,
      libraries: {
        StringLibrary: stringLibrary.address,
      },
    }
  );
  // deploy contract
  const orderManagementSystem = await OrderManagementSystem.deploy();

  return orderManagementSystem;
};
