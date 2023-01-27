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
  const pairFactory = await deployments.get('PairFactory')
  await deploy('Router', {
    from: deployer,
    args: [pairFactory.address, ARB_TEST_CONFIG.WETH],
    log: true,
    skipIfAlreadyDeployed: false
  })
}
exports.default = func
func.tags = ['Router']
func.id = 'router'
