"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const func = async function (hre) {
    const { deployments, getNamedAccounts } = hre;
    const { deploy } = deployments;
    const { deployer } = await getNamedAccounts();
    const escrow = await deployments.get('VotingEscrow');
    const voter = await deployments.get('Voter');
    const dist = await deployments.get('RewardsDistributor');
    await deploy('Minter', {
        from: deployer,
        args: [voter.address, escrow.address, dist.address],
        log: true,
        skipIfAlreadyDeployed: false
    });
};
exports.default = func;
func.tags = ['Minter'];
func.id = 'minter';
