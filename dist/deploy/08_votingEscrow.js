"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const func = async function (hre) {
    const { deployments, getNamedAccounts } = hre;
    const { deploy } = deployments;
    const { deployer } = await getNamedAccounts();
    const flow = await deployments.get('Flow');
    const veArtProxy = await deployments.get('VeArtProxy');
    await deploy('VotingEscrow', {
        from: deployer,
        args: [flow.address, veArtProxy.address],
        log: true,
        skipIfAlreadyDeployed: false
    });
};
exports.default = func;
func.tags = ['VotingEscrow'];
func.id = 'votingEscrow';
