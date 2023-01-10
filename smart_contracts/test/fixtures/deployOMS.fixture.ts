import hre, { ethers } from "hardhat";

const deployOMS = async (deployer: any) => {
  const StringLibrary = await ethers.getContractFactory("StringLibrary");
  const stringLibrary = await StringLibrary.deploy();
  await stringLibrary.deployed();

  const BytesLibrary = await ethers.getContractFactory("BytesLibrary");
  const bytesLibrary = await BytesLibrary.deploy();
  await bytesLibrary.deployed();

  const OrderManagementSystem = await ethers.getContractFactory(
    "OrderManagementSystem",
    {
      signer: deployer,
      libraries: {
        StringLibrary: stringLibrary.address,
        BytesLibrary: bytesLibrary.address,
      },
    }
  );
  // deploy contract
  const orderManagementSystem = await OrderManagementSystem.deploy();

  return orderManagementSystem;
};

export { deployOMS };
