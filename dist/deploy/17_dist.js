'use strict'
var __importDefault =
  (this && this.__importDefault) ||
  function (mod) {
    return mod && mod.__esModule ? mod : { default: mod }
  }
Object.defineProperty(exports, '__esModule', { value: true })
const arbTestnetConfig_1 = __importDefault(
  require('../tasks/deploy/constants/arbConfig')
)
const ARB_TEST_CONFIG = arbTestnetConfig_1.default
const func = async function (hre) {
  const { ethers } = hre
  const minter = await ethers.getContract('Minter')
  // Initial veVELO distro  this is already done by now in init...
  // await minter.initialize(
  //   ARB_TEST_CONFIG.partnerAddrs,
  //   ARB_TEST_CONFIG.partnerAmts,
  //   ARB_TEST_CONFIG.partnerMax
  // )  this is inside of dist and it does not run apparently...
  console.log('veVELO distributed')
  console.log('Arbitrum Goerli Velocimeter Instruments deployed')
  return true
}
exports.default = func
func.tags = ['initial_dist']
func.id = 'initial_dist'
