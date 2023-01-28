import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { DeployFunction } from 'hardhat-deploy/types'

//import arbTestnetConfig from '../tasks/deploy/constants/arbTestnetConfig'
import arbConfig from '../tasks/deploy/constants/arbConfig'

const ARB_TEST_CONFIG = arbConfig

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre
  const { deploy } = deployments

  const { deployer } = await getNamedAccounts()

  const flow = await deployments.get('Flow')

  await deploy('MerkleClaim', {
    from: deployer,
    args: [flow.address, ARB_TEST_CONFIG.merkleRoot],
    log: true,
    skipIfAlreadyDeployed: false
  })
}
export default func
func.tags = ['MerkleClaim']
func.id = 'merkleClaim'
