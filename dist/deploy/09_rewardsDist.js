"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const func = async function (hre) {
    const { deployments, getNamedAccounts } = hre;
    const { deploy } = deployments;
    const { deployer } = await getNamedAccounts();
    const escrow = await deployments.get("VotingEscrow");
    await deploy("RewardsDistributor", {
        from: deployer,
        args: [escrow.address],
        log: true,
        skipIfAlreadyDeployed: true,
    });
};
exports.default = func;
func.tags = ["RewardsDistributor"];
func.id = "rewardsDistributor";
