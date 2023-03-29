import { ethers } from "ethers";

const TOKEN_DECIMALS = ethers.BigNumber.from("10").pow(
  ethers.BigNumber.from("18")
);
const MILLION = ethers.BigNumber.from("10").pow(ethers.BigNumber.from("6"));

const FOUR_MILLION = ethers.BigNumber.from("4")
  .mul(MILLION)
  .mul(TOKEN_DECIMALS);
const TWENTY_MILLION = ethers.BigNumber.from("20")
  .mul(MILLION)
  .mul(TOKEN_DECIMALS);
const PARTNER_MAX = ethers.BigNumber.from("78")
  .mul(MILLION)
  .mul(TOKEN_DECIMALS);

const TEAM_MULTISIG = "0x790ac11183ddE23163b307E3F7440F2460526957";
const TEAM_EOA = "0x790ac11183ddE23163b307E3F7440F2460526957";

const testConfluxConfig = {
  // Chain const
  lzChainId: 71,

  // TODO: this is a layoutZero Endpoint
  lzEndpoint: "0x790ac11183ddE23163b307E3F7440F2460526957",

  // Tokens
  WCFX: "0x2ed3dddae5b2f321af0806181fbfa6d049be47d8",
  XCFX: "0x3e3608c5145e6bb303947e77d329811f14e76d26",
  USDT: "0xe69a3a7e23a06a9da7d0981aa82e367c7367db2e",
  USDC: "0xb1aebed41999273366e38e1858680f2574f521f9",
  AUSD: "0xcea2b4d593b87fab8352e9f08d809a06a205da9f",

  // Addresses
  teamEOA: TEAM_EOA,
  teamMultisig: TEAM_MULTISIG,
  emergencyCouncil: "0x790ac11183ddE23163b307E3F7440F2460526957",
  
  tokenWhitelist: [
    "0x2ed3dddae5b2f321af0806181fbfa6d049be47d8",
    "0x3e3608c5145e6bb303947e77d329811f14e76d26",
    "0xe69a3a7e23a06a9da7d0981aa82e367c7367db2e",
    "0xb1aebed41999273366e38e1858680f2574f521f9",
    "0xcea2b4d593b87fab8352e9f08d809a06a205da9f"
  ],
  partnerAddrs: [
    "0x790ac11183ddE23163b307E3F7440F2460526957"
  ],
  partnerAmts: [
    FOUR_MILLION
  ],
  partnerMax: FOUR_MILLION,
};

export default testConfluxConfig;
