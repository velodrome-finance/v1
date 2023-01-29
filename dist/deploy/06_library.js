"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const func = async function (hre) {
    const { deployments, getNamedAccounts } = hre;
    const { deploy } = deployments;
    const { deployer } = await getNamedAccounts();
    const router = await deployments.get('Router');
    await deploy('VelocimeterLibrary', {
        from: deployer,
        args: [router.address],
        log: true,
        skipIfAlreadyDeployed: false
    });
};
exports.default = func;
func.tags = ['VelocimeterLibrary'];
func.id = 'velocimeterLibrary';
