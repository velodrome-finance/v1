"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const func = async function (hre) {
    const { deployments, getNamedAccounts } = hre;
    const { deploy } = deployments;
    const { deployer } = await getNamedAccounts();
    await deploy("GaugeFactory", {
        from: deployer,
        args: [],
        log: true,
        skipIfAlreadyDeployed: true,
    });
};
exports.default = func;
func.tags = ["GaugeFactory"];
func.id = "gaugeFactory";
