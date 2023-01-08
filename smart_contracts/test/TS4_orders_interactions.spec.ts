import { expect } from "chai";
import { ethers } from "hardhat";

import deployOMS from "./utils/deployOMS";
import { any } from "hardhat/internal/core/params/argumentTypes";

import { OrderManagementSystem } from "../typechain-types/contracts";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { BigNumber } from "ethers/lib/ethers";

describe("#TS4: orders interactions", function () {
  let owner: SignerWithAddress;
  let orderManagementSystem: OrderManagementSystem;

  before(async function () {
    [owner] = await ethers.getSigners();
    orderManagementSystem = await deployOMS(owner);
  });

  it("", async function () {});
});
