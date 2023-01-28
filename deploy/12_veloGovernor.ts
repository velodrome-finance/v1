import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { DeployFunction } from 'hardhat-deploy/types'

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre
  const { deploy } = deployments

  const { deployer } = await getNamedAccounts()

  const escrow = await deployments.get('VotingEscrow')

  await deploy('FlowGovernor', {
    from: deployer,
    args: [escrow.address],
    log: true,
    skipIfAlreadyDeployed: false
  })
}
export default func
func.tags = ['FlowGovernor']
func.id = 'FlowGovernor'
