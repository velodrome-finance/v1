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
  const { deployments, getNamedAccounts } = hre
  const { deploy } = deployments
  const { deployer } = await getNamedAccounts()
  const flow = await deployments.get('Flow')
  await deploy('MerkleClaim', {
    from: deployer,
    args: [flow.address, ARB_TEST_CONFIG.merkleRoot],
    log: true,
    skipIfAlreadyDeployed: true
  })
}
exports.default = func
func.tags = ['MerkleClaim']
func.id = 'merkleClaim'
