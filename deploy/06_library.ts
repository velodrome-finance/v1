import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;

  const { deployer } = await getNamedAccounts();

  const router = await deployments.get("Router");

  await deploy("VelodromeLibrary", {
    from: deployer,
    args: [router.address],
    log: true,
  });
};
export default func;
func.tags = ["VelodromeLibrary"];
