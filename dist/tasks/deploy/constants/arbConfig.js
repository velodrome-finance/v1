'use strict'
Object.defineProperty(exports, '__esModule', { value: true })
const ethers_1 = require('ethers')
const TOKEN_DECIMALS = ethers_1.ethers.BigNumber.from('10').pow(
  ethers_1.ethers.BigNumber.from('18')
)

const MILLION = ethers_1.ethers.BigNumber.from('1').pow(
  ethers_1.ethers.BigNumber.from('6')
)
const FOUR_MILLION = ethers_1.ethers.BigNumber.from('4')
  .mul(MILLION)
  .mul(TOKEN_DECIMALS)
const TWO_MILLION = ethers_1.ethers.BigNumber.from('2')
  .mul(MILLION)
  .mul(TOKEN_DECIMALS)
const TEN_MILLION = ethers_1.ethers.BigNumber.from('10')
  .mul(MILLION)
  .mul(TOKEN_DECIMALS)
const TWELVE_MILLION = ethers_1.ethers.BigNumber.from('12')
  .mul(MILLION)
  .mul(TOKEN_DECIMALS)
const SIXTY_MILLION = ethers_1.ethers.BigNumber.from('60')
  .mul(MILLION)
  .mul(TOKEN_DECIMALS)
const PARTNER_MAX = ethers_1.ethers.BigNumber.from('78')
  .mul(MILLION)
  .mul(TOKEN_DECIMALS)
const TEAM_MULTISIG = '0x16ec7CD5E35682B751d0c77c41A4e6a1A3E2DE01'
const TEAM_EOA = '0x16ec7CD5E35682B751d0c77c41A4e6a1A3E2DE01'
const arbConfig = {
  // Chain const
  lzChainId: 110,
  lzEndpoint: '0x3c2269811836af69497E5F486A85D7316753cf62',
  // Tokens
  WETH: '0x82aF49447D8a07e3bd95BD0d56f35241523fBab1',
  USDC: '0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8',

  // Addresses
  teamEOA: TEAM_EOA,
  teamMultisig: TEAM_MULTISIG,
  coolie: TEAM_EOA,
  dunks: '0x069e85D4F1010DD961897dC8C095FBB5FF297434',
  ceazor: '0x3c5Aac016EF2F178e8699D6208796A2D67557fe2',
  faeflow: TEAM_EOA, //update
  wtck: TEAM_EOA,
  torbik: TEAM_EOA,
  velodromeMultisig: TEAM_EOA,

  emergencyCouncil: '0xcC2D01030eC2cd187346F70bFc483F24488C32E8',
  merkleRoot:
    '0xbb99a09fb3b8499385659e82a8da93596dd07082fe86981ec06c83181dee489f',
  tokenWhitelist: [
    // tokens whitelisted for gauges
    '0x4200000000000000000000000000000000000042',
    '0x4200000000000000000000000000000000000006',
    '0x7F5c764cBc14f9669B88837ca1490cCa17c31607',
    '0x2E3D870790dC77A83DD1d18184Acc7439A53f475',
    '0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1',
    '0x8c6f28f2F1A3C87F0f938b96d27520d9751ec8d9',
    '0x217D47011b23BB961eB6D93cA9945B7501a5BB11',
    '0x50c5725949A6F0c72E6C4a641F24049A917DB0Cb',
    '0x67CCEA5bb16181E7b4109c9c2143c24a1c2205Be',
    '0x9e1028F5F1D5eDE59748FFceE5532509976840E0',
    '0x8700dAec35aF8Ff88c16BdF0418774CB3D7599B4',
    '0xCB8FA9a76b8e203D8C3797bF438d8FB81Ea3326A',
    '0x3E29D3A9316dAB217754d13b28646B76607c5f04',
    '0x8aE125E8653821E851F12A49F7765db9a9ce7384',
    '0x10010078a54396F62c96dF8532dc2B4847d47ED3',
    // "", // BTRFLY -- N/A
    // "", // pxFLOW -- N/A
    '0xc40F949F8a4e094D1b49a23ea9241D289B7b2819' // LUSD
    // "", // wstETH -- N/A
    // "", // HOP -- N/A
  ],
  partnerAddrs: [
    TEAM_MULTISIG, // Protocol owned NFT 64m
    '0x069e85D4F1010DD961897dC8C095FBB5FF297434', // dunks
    '0x3c5Aac016EF2F178e8699D6208796A2D67557fe2', // ceazor
    '0x03B88DacB7c21B54cEfEcC297D981E5b721A9dF1', //coolie
    
   
     ''//faeflow,
     '0x78e801136F77805239A7F533521A7a5570F572C8', //wtck,
     '0x0b776552c1Aef1Dc33005DD25AcDA22493b6615d',//torbik,
    velodromeMultisig,
    TEAM_MULTISIG,
    TEAM_MULTISIG,
    TEAM_MULTISIG,
    TEAM_MULTISIG,
    TEAM_MULTISIG,
    TEAM_MULTISIG,
    TEAM_MULTISIG,
    TEAM_MULTISIG,
    TEAM_MULTISIG,
    TEAM_MULTISIG,
    TEAM_MULTISIG,
    TEAM_MULTISIG,
    TEAM_MULTISIG,
    TEAM_MULTISIG,
    TEAM_MULTISIG,
    TEAM_MULTISIG,
    TEAM_MULTISIG,
    TEAM_MULTISIG,
    TEAM_MULTISIG,
    TEAM_MULTISIG,
    TEAM_MULTISIG,
    TEAM_MULTISIG,
    TEAM_MULTISIG,
    TEAM_MULTISIG,
    TEAM_MULTISIG,
    TEAM_MULTISIG,
    TEAM_MULTISIG,
    TEAM_MULTISIG,
    TEAM_MULTISIG,
    TEAM_MULTISIG,
    TEAM_MULTISIG,
    TEAM_MULTISIG,
    TEAM_MULTISIG,
    TEAM_MULTISIG,
    TEAM_MULTISIG,
    TEAM_MULTISIG,
    TEAM_MULTISIG,
    TEAM_MULTISIG // 38 x protcol / partner NFTs
  ],
  partnerAmts: [
    SIXTY_MILLION, // 60 million for protcol owned NFT 15% 
    TWO_MILLION, // dunks presale
    TWO_MILLION, // ceazor presale
    FOUR_MILLION, // team veFLOW 1%
    FOUR_MILLION, // team veFLOW 1%
    FOUR_MILLION, // team veFLOW 1%
    FOUR_MILLION, // team veFLOW 1%
    FOUR_MILLION, // team veFLOW 1%
    FOUR_MILLION, // team veFLOW 1%
    FOUR_MILLION, // tribute to velodrome (need to get their arb address DO NOT USE MULTISIG FROM OP)
    FOUR_MILLION,
    FOUR_MILLION,
    FOUR_MILLION,
    FOUR_MILLION,
    FOUR_MILLION,
    FOUR_MILLION,
    FOUR_MILLION,
    FOUR_MILLION,
    FOUR_MILLION,
    FOUR_MILLION,
    FOUR_MILLION,
    FOUR_MILLION,
    FOUR_MILLION,
    FOUR_MILLION,
    FOUR_MILLION,
    FOUR_MILLION,
    FOUR_MILLION,
    FOUR_MILLION,
    FOUR_MILLION,
    FOUR_MILLION,
    FOUR_MILLION,
    FOUR_MILLION,
    FOUR_MILLION,
    FOUR_MILLION,
    FOUR_MILLION,
    FOUR_MILLION,
    FOUR_MILLION,
    FOUR_MILLION,
    FOUR_MILLION,
    FOUR_MILLION,
    FOUR_MILLION,
    FOUR_MILLION,
    FOUR_MILLION,
    FOUR_MILLION,
    FOUR_MILLION,
    FOUR_MILLION,
    FOUR_MILLION,
    FOUR_MILLION,
    FOUR_MILLION // 1% to each partner x 38 partners
  ],
  partnerMax: PARTNER_MAX
}
exports.default = arbConfig
