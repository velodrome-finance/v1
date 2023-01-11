import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";

import arbTestnetConfig from "../tasks/deploy/constants/arbTestnetConfig";

const ARB_TEST_CONFIG = arbTestnetConfig;

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { ethers } = hre;
  const minter = await ethers.getContract("Minter");

  // Initial veVELO distro
  await minter.initialize(
    ARB_TEST_CONFIG.partnerAddrs,
    ARB_TEST_CONFIG.partnerAmts,
    ARB_TEST_CONFIG.partnerMax
  );
  console.log("veVELO distributed");

  console.log("Arbitrum Goerli Velocimeter Instruments deployed");

  return true;
};
export default func;
func.tags = ["initial_dist"];
func.id = "initial_dist";
