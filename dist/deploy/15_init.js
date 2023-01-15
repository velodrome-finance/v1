'use strict'
var __importDefault =
  (this && this.__importDefault) ||
  function (mod) {
    return mod && mod.__esModule ? mod : { default: mod }
  }
Object.defineProperty(exports, '__esModule', { value: true })
const arbTestnetConfig_1 = __importDefault(
  require('../tasks/deploy/constants/arbTestnetConfig')
)
const ARB_TEST_CONFIG = arbTestnetConfig_1.default
const func = async function (hre) {
  const { deployments, ethers } = hre
  const velo = await ethers.getContract('Velo')
  const pairFactory = await ethers.getContract('PairFactory')
  const escrow = await ethers.getContract('VotingEscrow')
  const voter = await ethers.getContract('Voter')
  const distributor = await ethers.getContract('RewardsDistributor')
  const governor = await ethers.getContract('VeloGovernor')
  const minter = await ethers.getContract('Minter')
  const receiver = await ethers.getContract('RedemptionReceiver')
  const claim = await deployments.get('MerkleClaim')
  // Initialize
  await velo.initialMint(ARB_TEST_CONFIG.teamEOA)
  console.log('Initial minted')
  await velo.setRedemptionReceiver(receiver.address)
  console.log('RedemptionReceiver set')
  await velo.setMerkleClaim(claim.address)
  console.log('MerkleClaim set')
  await velo.setMinter(minter.address)
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
  return true
}
exports.default = func
func.tags = ['init_deploy']
func.id = 'init_deploy'
