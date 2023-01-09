import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";

import arbTestnetConfig from "../tasks/deploy/constants/arbTestnetConfig";
import testFantomConfig from "../tasks/deploy/constants/testFantomConfig";

const ARB_TEST_CONFIG = arbTestnetConfig;
const FTM_CONFIG = testFantomConfig;

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;

  const { deployer } = await getNamedAccounts();

  const velo = await deployments.get("Velo");

  await deploy("RedemptionReceiver", {
    from: deployer,
    args: [
      ARB_TEST_CONFIG.USDC,
      velo.address,
      FTM_CONFIG.lzChainId,
      ARB_TEST_CONFIG.lzEndpoint,
    ],
    log: true,
  });
};
export default func;
func.tags = ["RedemptionReceiver"];
