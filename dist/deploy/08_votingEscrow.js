"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const func = async function (hre) {
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
exports.default = func;
func.tags = ["VotingEscrow"];
func.id = "votingEscrow";
