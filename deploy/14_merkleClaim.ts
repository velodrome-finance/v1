import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";

import arbTestnetConfig from "../tasks/deploy/constants/arbTestnetConfig";

const ARB_TEST_CONFIG = arbTestnetConfig;

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;

  const { deployer } = await getNamedAccounts();

  const velo = await deployments.get("Velo");

  await deploy("MerkleClaim", {
    from: deployer,
    args: [velo.address, ARB_TEST_CONFIG.merkleRoot],
    log: true,
  });
};
export default func;
func.tags = ["MerkleClaim"];
