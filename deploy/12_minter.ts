import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { DeployFunction } from 'hardhat-deploy/types'

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre
  const { deploy } = deployments

  const { deployer } = await getNamedAccounts()

  const escrow = await deployments.get('VotingEscrow')
  const voter = await deployments.get('Voter')
  const dist = await deployments.get('RewardsDistributor')

  await deploy('Minter', {
    from: deployer,
    args: [voter.address, escrow.address, dist.address],
    log: true,
    skipIfAlreadyDeployed: false
  })
}
export default func
func.tags = ['Minter']
func.id = 'minter'
