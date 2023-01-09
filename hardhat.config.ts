import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-waffle";
import "@typechain/hardhat";
import "hardhat-preprocessor";
import "hardhat-abi-exporter";
import "hardhat-deploy";

import fs from "fs";
import { resolve } from "path";

import { config as dotenvConfig } from "dotenv";
import { HardhatUserConfig } from "hardhat/config";

dotenvConfig({ path: resolve(__dirname, "./.env") });
import "./checkEnv";

const remappings = fs
  .readFileSync("remappings.txt", "utf8")
  .split("\n")
  .filter(Boolean)
  .map((line) => line.trim().split("="));

const config: HardhatUserConfig = {
  networks: {
    hardhat: {
      initialBaseFeePerGas: 0,
      forking: {
        url: `https://arb-mainnet.g.alchemy.com/v2/${process.env.ALCHEMY_MAINNET_ARBITRUM_API_KEY}`,
        blockNumber: 16051852,
      },
    },
    opera: {
      url: "https://rpc.fantom.network",
      accounts: [process.env.PRIVATE_KEY!],
    },
    arbitrum: {
      url: `https://arb-mainnet.g.alchemy.com/v2/${process.env.ALCHEMY_MAINNET_ARBITRUM_API_KEY}`,
      accounts: [process.env.PRIVATE_KEY!],
      chainId: 42161,
      saveDeployments: true,
      verify: {
        etherscan: {
          apiUrl: "https://api.arbiscan.io/api",
        },
      },
    },
    arbitrumGoerli: {
      url: `https://arb-goerli.g.alchemy.com/v2/${process.env.ALCHEMY_GOERLI_ARBITRUM_API_KEY}`,
      accounts: [process.env.PRIVATE_KEY!],
      chainId: 421613,
      saveDeployments: true,
      verify: {
        etherscan: {
          apiUrl: "https://api-goerli.arbiscan.io/",
          apiKey: process.env.ARB_SCAN_API_KEY!,
        },
      },
    },
    ftmTestnet: {
      url: "https://rpc.testnet.fantom.network",
      accounts: [process.env.PRIVATE_KEY!],
    },
    optimisticEthereum: {
      url: "https://mainnet.optimism.io",
      accounts: [process.env.PRIVATE_KEY!],
    },
    optimisticKovan: {
      url: "https://kovan.optimism.io",
      accounts: [process.env.PRIVATE_KEY!],
    },
  },
  solidity: {
    version: "0.8.13",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  namedAccounts: {
    deployer: 0,
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
      arbitrum: process.env.ARB_SCAN_API_KEY!,
      arbitrumGoerli: process.env.ARB_SCAN_API_KEY!,
    },
  },
};

export default config;
