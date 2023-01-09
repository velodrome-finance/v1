import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;

  const { deployer } = await getNamedAccounts();

  const escrow = await deployments.get("VotingEscrow");

  await deploy("RewardsDistributor", {
    from: deployer,
    args: [escrow.address],
    log: true,
  });
};
export default func;
func.tags = ["RewardsDistributor"];
