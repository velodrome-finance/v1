import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-waffle";
import "@typechain/hardhat";
import "hardhat-preprocessor";
import "hardhat-abi-exporter";
import "hardhat-deploy";
import { HardhatUserConfig } from "hardhat/config";
import "./checkEnv";
declare const config: HardhatUserConfig;
export default config;