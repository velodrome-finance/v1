'use strict'
var __importDefault =
  (this && this.__importDefault) ||
  function (mod) {
    return mod && mod.__esModule ? mod : { default: mod }
  }
Object.defineProperty(exports, '__esModule', { value: true })
const arbTestnetConfig_1 = __importDefault(
  require('../tasks/deploy/constants/arbTestnetConfig')
)
const ARB_TEST_CONFIG = arbTestnetConfig_1.default
const func = async function (hre) {
  const { ethers } = hre
  const flow = await ethers.getContract('Flow')
  const voter = await ethers.getContract('Voter')
  const minter = await ethers.getContract('Minter')
  // Whitelist
  const nativeToken = [flow.address]
  const tokenWhitelist = nativeToken.concat(ARB_TEST_CONFIG.tokenWhitelist)
  await voter.initialize(tokenWhitelist, minter.address)
  console.log('Whitelist set')
  return true
}
exports.default = func
func.tags = ['whitelist']
func.id = 'whitelist'
