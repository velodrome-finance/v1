import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { DeployFunction } from 'hardhat-deploy/types'

import arbConfig from '../tasks/deploy/constants/arbConfig'
import testFantomConfig from '../tasks/deploy/constants/testFantomConfig'

const ARB_TEST_CONFIG = arbConfig
const FTM_CONFIG = testFantomConfig

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre
  const { deploy } = deployments

  const { deployer } = await getNamedAccounts()

  const flow = await deployments.get('Flow')

  await deploy('RedemptionReceiver', {
    from: deployer,
    args: [
      ARB_TEST_CONFIG.USDC,
      flow.address,
      FTM_CONFIG.lzChainId,
      ARB_TEST_CONFIG.lzEndpoint
    ],
    log: true,
    skipIfAlreadyDeployed: false
  })
}
export default func
func.tags = ['RedemptionReceiver']
func.id = 'redemptionReceiver'
