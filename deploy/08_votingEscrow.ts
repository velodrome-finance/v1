import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { DeployFunction } from 'hardhat-deploy/types'

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre
  const { deploy } = deployments

  const { deployer } = await getNamedAccounts()

  const flow = await deployments.get('Flow')
  const veArtProxy = await deployments.get('VeArtProxy')

  await deploy('VotingEscrow', {
    from: deployer,
    args: [flow.address, veArtProxy.address],
    log: true,
    skipIfAlreadyDeployed: false
  })
}
export default func
func.tags = ['VotingEscrow']
func.id = 'votingEscrow'
