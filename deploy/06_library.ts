import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { DeployFunction } from 'hardhat-deploy/types'

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre
  const { deploy } = deployments

  const { deployer } = await getNamedAccounts()

  const router = await deployments.get('Router')

  await deploy('VelocimeterLibrary', {
    from: deployer,
    args: [router.address],
    log: true,
    skipIfAlreadyDeployed: false
  })
}
export default func
func.tags = ['VelocimeterLibrary']
func.id = 'velocimeterLibrary'
