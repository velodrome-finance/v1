"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const config_1 = require("hardhat/config");
const optimismConfig_1 = __importDefault(require("./constants/optimismConfig"));
const testOptimismConfig_1 = __importDefault(require("./constants/testOptimismConfig"));
const fantomConfig_1 = __importDefault(require("./constants/fantomConfig"));
const testFantomConfig_1 = __importDefault(require("./constants/testFantomConfig"));
const deployed_1 = __importDefault(require("./constants/deployed"));
(0, config_1.task)("deploy:ftm", "Deploys Fantom contracts").setAction(async function (taskArguments, { ethers }) {
    const mainnet = false;
    const OP_CONFIG = mainnet ? optimismConfig_1.default : testOptimismConfig_1.default;
    const FTM_CONFIG = mainnet ? fantomConfig_1.default : testFantomConfig_1.default;
    // CHECK that optimismReceiver is not empty for network
    if (deployed_1.default.optimismReceiver.length === 0) {
        throw "receiver not set";
    }
    // Load
    const RedemptionSender = await ethers.getContractFactory("RedemptionSender");
    // Deploy
    const sender = await RedemptionSender.deploy(FTM_CONFIG.WEVE, OP_CONFIG.lzChainId, FTM_CONFIG.lzEndpoint, deployed_1.default.optimismReceiver);
    console.log("RedemptionSender deployed to: ", sender.address);
    console.log("Args: ", FTM_CONFIG.WEVE, OP_CONFIG.lzChainId, FTM_CONFIG.lzEndpoint, deployed_1.default.optimismReceiver, "\n");
    console.log("Fantom contracts deployed");
});
