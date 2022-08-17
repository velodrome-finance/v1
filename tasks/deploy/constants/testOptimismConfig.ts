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

const TEAM_MULTISIG = "0x52f02a075191F69E30917effc66087ad981Db703";
const TEAM_EOA = "0x52f02a075191F69E30917effc66087ad981Db703";

const testOptimismArgs = {
  // Chain const
  lzChainId: 10011,
  lzEndpoint: "0x72aB53a133b27Fa428ca7Dc263080807AfEc91b5",

  // Tokens
  WETH: "0x4200000000000000000000000000000000000006",
  USDC: "0x3e22e37Cb472c872B5dE121134cFD1B57Ef06560",

  // Addresses
  teamEOA: TEAM_EOA,
  teamMultisig: TEAM_MULTISIG,
  emergencyCouncil: "0x52f02a075191F69E30917effc66087ad981Db703",

  merkleRoot:
    "",
  tokenWhitelist: [
    "0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1",
    "0xbC6F6b680bc61e30dB47721c6D1c5cde19C1300d",
    "0x0064A673267696049938AA47595dD0B3C2e705A1",
    "0x3e22e37Cb472c872B5dE121134cFD1B57Ef06560",
  ],
  partnerAddrs: [
    "0x52f02a075191F69E30917effc66087ad981Db703",
    "0x82D54397B88CE80Ea2Df9aD049213ACb47dc2523",
    "0x6122a6A39a6C3f2BCd96B929Fc2066204FDb125a",
    "0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199",
    "0xDEcc3156Bd9826a0034D829C35Dc3679Be5ac529",
    "0x203693De100D1527637167d89dce39D876B7821B",
    "0x4F7d04d96732515052751929362Ce6DA7622caCe",
    "0x53e0B897EAE600B2F6855FCe4a42482E9229D2c2",
    TEAM_EOA, // TEST
  ],
  partnerAmts: [
    TWENTY_MILLION,
    FOUR_MILLION,
    FOUR_MILLION,
    FOUR_MILLION,
    FOUR_MILLION,
    FOUR_MILLION,
    FOUR_MILLION,
    FOUR_MILLION,
    FOUR_MILLION,
  ],
  partnerMax: PARTNER_MAX,
};

export default testOptimismArgs;
