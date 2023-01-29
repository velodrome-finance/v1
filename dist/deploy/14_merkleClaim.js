"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
//import arbTestnetConfig from '../tasks/deploy/constants/arbTestnetConfig'
const arbConfig_1 = __importDefault(require("../tasks/deploy/constants/arbConfig"));
const ARB_TEST_CONFIG = arbConfig_1.default;
const func = async function (hre) {
    const { deployments, getNamedAccounts } = hre;
    const { deploy } = deployments;
    const { deployer } = await getNamedAccounts();
    const flow = await deployments.get('Flow');
    await deploy('MerkleClaim', {
        from: deployer,
        args: [flow.address, ARB_TEST_CONFIG.merkleRoot],
        log: true,
        skipIfAlreadyDeployed: false
    });
};
exports.default = func;
func.tags = ['MerkleClaim'];
func.id = 'merkleClaim';
