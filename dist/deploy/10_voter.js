'use strict'
Object.defineProperty(exports, '__esModule', { value: true })
const func = async function (hre) {
  const { deployments, getNamedAccounts } = hre
  const { deploy } = deployments
  const { deployer } = await getNamedAccounts()
  const escrow = await deployments.get('VotingEscrow')
  const pairFactory = await deployments.get('PairFactory')
  const gaugeFactory = await deployments.get('GaugeFactory')
  const bribeFactory = await deployments.get('BribeFactory')
  await deploy('Voter', {
    from: deployer,
    args: [
      escrow.address,
      pairFactory.address,
      gaugeFactory.address,
      bribeFactory.address
    ],
    log: true,
    skipIfAlreadyDeployed: false
  })
}
exports.default = func
func.tags = ['Voter']
func.id = 'voter'
