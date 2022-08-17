import { task } from "hardhat/config";

import optimismConfig from "./constants/optimismConfig";
import testOptimismConfig from "./constants/testOptimismConfig";

import fantomConfig from "./constants/fantomConfig";
import testFantomConfig from "./constants/testFantomConfig";

import deployed from "./constants/deployed";

task("deploy:ftm", "Deploys Fantom contracts").setAction(async function (
  taskArguments,
  { ethers }
) {
  const mainnet = false;

  const OP_CONFIG = mainnet ? optimismConfig : testOptimismConfig;
  const FTM_CONFIG = mainnet ? fantomConfig : testFantomConfig;

  // CHECK that optimismReceiver is not empty for network
  if (deployed.optimismReceiver.length === 0) {
    throw "receiver not set";
  }

  // Load
  const RedemptionSender = await ethers.getContractFactory("RedemptionSender");

  // Deploy
  const sender = await RedemptionSender.deploy(
    FTM_CONFIG.WEVE,
    OP_CONFIG.lzChainId,
    FTM_CONFIG.lzEndpoint,
    deployed.optimismReceiver
  );
  console.log("RedemptionSender deployed to: ", sender.address);
  console.log("Args: ",
    FTM_CONFIG.WEVE,
    OP_CONFIG.lzChainId,
    FTM_CONFIG.lzEndpoint,
    deployed.optimismReceiver,
    "\n"
  );

  console.log("Fantom contracts deployed");
});
