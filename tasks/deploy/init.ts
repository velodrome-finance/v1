// The tasks in this file should be called by the multisig
// CURRENTLY OUTDATED

// import { task } from "hardhat/config";
// import deployed from "./constants/deployed";

// task("deploy:init", "Initializes RedemptionSender on Optimism").setAction(
//   async function (taskArguments, { ethers }) {
//     // Define network
//     const network = "optimism-kovan"; // "optimism" for mainnet deploy

//     // PERFORM CHECKS ON ARGS

//     // TODO move
//     const TOKEN_DECIMALS = ethers.BigNumber.from("10").pow(
//       ethers.BigNumber.from("18")
//     );
//     const ELIGIBLE_WEVE =
//       ethers.BigNumber.from("375112540").mul(TOKEN_DECIMALS); // TODO fix rounding

//     const REDEEMABLE_USDC = ethers.BigNumber.from("0"); // TODO update
//     const REDEEMABLE_VELO =
//       ethers.BigNumber.from("108000000").mul(TOKEN_DECIMALS); // TODO fix rounding

//     // Load
//     const RedemptionReceiver = await ethers.getContractFactory(
//       "RedemptionReceiver"
//     );
//     const receiver = await RedemptionReceiver.attach(deployed.optimismReceiver);

//     // Initialize
//     await receiver.initializeReceiverWith(
//       deployed.fantomSender,
//       ELIGIBLE_WEVE,
//       REDEEMABLE_USDC,
//       REDEEMABLE_VELO
//     );
//     console.log(`RedemptionSender at ${receiver.address} configured!`);
//   }
// );
