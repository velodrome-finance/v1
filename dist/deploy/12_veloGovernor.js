'use strict'
Object.defineProperty(exports, '__esModule', { value: true })
const func = async function (hre) {
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
exports.default = func
func.tags = ['FlowGovernor']
func.id = 'FlowGovernor'
