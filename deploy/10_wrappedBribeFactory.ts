import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { DeployFunction } from 'hardhat-deploy/types'

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre
  const { deploy } = deployments

  const { deployer } = await getNamedAccounts()

  //   const escrow = await deployments.get('VotingEscrow')
  //   const pairFactory = await deployments.get('PairFactory')
  //   const gaugeFactory = await deployments.get('GaugeFactory')
  //   const bribeFactory = await deployments.get('BribeFactory')
  const voter = await deployments.get('Voter')

  await deploy('WrappedExternalBribeFactory', {
    from: deployer,
    args: [voter.address],
    log: true,
    skipIfAlreadyDeployed: false
  })
}
export default func
func.tags = ['WrappedExternalBribeFactory']
func.id = 'wrapped-external-bribe-factory'
