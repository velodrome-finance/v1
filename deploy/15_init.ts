import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { DeployFunction } from 'hardhat-deploy/types'

import arbHardhatConfig from '../tasks/deploy/constants/arbHardhatConfig'

const ARB_TEST_CONFIG = arbHardhatConfig

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, ethers } = hre

  const flow = await ethers.getContract('Flow')
  const pairFactory = await ethers.getContract('PairFactory')
  const escrow = await ethers.getContract('VotingEscrow')
  const voter = await ethers.getContract('Voter')
  const distributor = await ethers.getContract('RewardsDistributor')
  const governor = await ethers.getContract('VeloGovernor')
  const minter = await ethers.getContract('Minter')
  const receiver = await ethers.getContract('RedemptionReceiver')

  const claim = await deployments.get('MerkleClaim')

  // Initialize
  await flow.initialMint(ARB_TEST_CONFIG.teamEOA)
  console.log('Initial minted')

  await flow.setRedemptionReceiver(receiver.address)
  console.log('RedemptionReceiver set')

  await flow.setMerkleClaim(claim.address)
  console.log('MerkleClaim set')

  await flow.setMinter(minter.address)
  console.log('Minter set')

  await pairFactory.setPauser(ARB_TEST_CONFIG.teamMultisig)
  console.log('Pauser set')

  await escrow.setVoter(voter.address)
  console.log(
    'Voter set',
    'voter address: ',
    voter.address,
    'escrow address: ',
    escrow.address
  )

  await escrow.setTeam(ARB_TEST_CONFIG.teamMultisig)
  console.log('Team set for escrow')

  await voter.setGovernor(ARB_TEST_CONFIG.teamMultisig)
  console.log('Governor set')

  await voter.setEmergencyCouncil(ARB_TEST_CONFIG.teamMultisig)
  console.log('Emergency Council set')

  await distributor.setDepositor(minter.address)
  console.log('Depositor set')

  await receiver.setTeam(ARB_TEST_CONFIG.teamMultisig)
  console.log('Team set for receiver')

  await governor.setTeam(ARB_TEST_CONFIG.teamMultisig)
  console.log('Team set for governor')

  await minter.setTeam(ARB_TEST_CONFIG.teamMultisig)
  console.log('Team set for minter')

  // create pair
  // provide liq
  // etc etc
  // see forge tests for more details

  return true
}
export default func
func.tags = ['init_deploy']
func.id = 'init_deploy'
