import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-waffle";
import "@typechain/hardhat";
import "hardhat-preprocessor";
import "hardhat-abi-exporter";

import "@matterlabs/hardhat-zksync-deploy";
import "@matterlabs/hardhat-zksync-solc";

import "./tasks/accounts";
import "./tasks/deploy";

import fs from "fs";
import { resolve } from "path";

import { config as dotenvConfig } from "dotenv";
import { HardhatUserConfig, task } from "hardhat/config";

dotenvConfig({ path: resolve(__dirname, "./.env") });

const remappings = fs
  .readFileSync("remappings.txt", "utf8")
  .split("\n")
  .filter(Boolean)
  .map((line) => line.trim().split("="));

const config: HardhatUserConfig = {
  defaultNetwork: "zkTestnet",
  networks: {
    hardhat: {
      initialBaseFeePerGas: 0,
      forking: {
        url: `https://opt-mainnet.g.alchemy.com/v2/${process.env.ALCHEMY_API_KEY}`,
        blockNumber: 16051852
      }
    },
    opera: {
      url: "https://rpc.fantom.network",
      accounts: [process.env.PRIVATE_KEY!],
      zksync: false,
    },
    ftmTestnet: {
      url: "https://rpc.testnet.fantom.network",
      accounts: [process.env.PRIVATE_KEY!],
      zksync: false,
    },
    optimisticEthereum: {
      url: "https://mainnet.optimism.io",
      accounts: [process.env.PRIVATE_KEY!],
      zksync: false,
    },
    optimisticKovan: {
      url: "https://kovan.optimism.io",
      accounts: [process.env.PRIVATE_KEY!],
      zksync: false,
    },
    zkTestnet: {
      url: "https://testnet.era.zksync.dev",
      ethNetwork: "goerli", // Can also be the RPC URL of the Ethereum network (e.g. `https://goerli.infura.io/v3/<API_KEY>`)
      zksync: true,
    },
  },
  // solidity: {
  //   version: "0.8.13",
  //   settings: {
  //     optimizer: {
  //       enabled: true,
  //       runs: 200,
  //     },
  //   },
  // },
  zksolc: {
    version: "1.3.5",
    compilerSource: "binary",
    settings: {},
  },
  solidity: {
    version: "0.8.13",
  },
  // This fully resolves paths for imports in the ./lib directory for Hardhat
  preprocess: {
    eachLine: (hre) => ({
      transform: (line: string) => {
        if (!line.match(/^\s*import /i)) {
          return line;
        }

        const remapping = remappings.find(([find]) => line.match('"' + find));
        if (!remapping) {
          return line;
        }

        const [find, replace] = remapping;
        return line.replace('"' + find, '"' + replace);
      },
    }),
  },
  etherscan: {
    apiKey: {
      opera: process.env.FTM_SCAN_API_KEY!,
      ftmTestnet: process.env.FTM_SCAN_API_KEY!,
      optimisticEthereum: process.env.OP_SCAN_API_KEY!,
      optimisticKovan: process.env.OP_SCAN_API_KEY!,
    }
  }
};

export default config;
