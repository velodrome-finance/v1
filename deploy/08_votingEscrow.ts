import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;

  const { deployer } = await getNamedAccounts();

  const velo = await deployments.get("Velo");
  const veArtProxy = await deployments.get("VeArtProxy");

  await deploy("VotingEscrow", {
    from: deployer,
    args: [velo.address, veArtProxy.address],
    log: true,
    skipIfAlreadyDeployed: true,
  });
};
export default func;
func.tags = ["VotingEscrow"];
func.id = "votingEscrow";