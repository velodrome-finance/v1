import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { DeployFunction } from 'hardhat-deploy/types'
// import * as tasks1 from 'tasks/deploy/arbHardhat'

import arbTestnetConfig from '../tasks/deploy/constants/arbTestnetConfig'
import arbHardhatConfig from '../tasks/deploy/constants/arbHardhatConfig'

const ARB_TEST_CONFIG = arbHardhatConfig

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { ethers } = hre
  const minter = await ethers.getContract('Minter')

  const { deployments, getNamedAccounts } = hre
  const { deploy } = deployments

  const { deployer } = await getNamedAccounts()

  const velo = await deployments.get('Velo')

  // Initial veVELO distro
  await minter.initialize(
    ARB_TEST_CONFIG.partnerAddrs,
    ARB_TEST_CONFIG.partnerAmts,
    ARB_TEST_CONFIG.partnerMax
  )
  console.log('veVELO distributed')
  //
  console.log('Arbitrum Goerli Velocimeter Instruments deployed')

  return true
  // Initialize

  console.log('deployer', deployer)

  // await velo.initialMint(ARB_CONFIG.teamEOA)
  // console.log('Initial minted')

  // await velo.setRedemptionReceiver(receiver.address)
  // console.log('RedemptionReceiver set')

  // await velo.setMerkleClaim(claim.address)
  // console.log('MerkleClaim set')

  // await velo.setMinter(minter.address)
  // console.log('Minter set')

  // await pairFactory.setPauser(ARB_CONFIG.teamMultisig)
  // console.log('Pauser set')

  // await escrow.setVoter(voter.address)
  // console.log('Voter set')

  // await escrow.setTeam(ARB_CONFIG.teamMultisig)
  // console.log('Team set for escrow')

  // await voter.setGovernor(ARB_CONFIG.teamMultisig)
  // console.log('Governor set')

  // await voter.setEmergencyCouncil(ARB_CONFIG.teamMultisig)
  // console.log('Emergency Council set')

  // await distributor.setDepositor(minter.address)
  // console.log('Depositor set')

  // await receiver.setTeam(ARB_CONFIG.teamMultisig)
  // console.log('Team set for receiver')

  // await governor.setTeam(ARB_CONFIG.teamMultisig)
  // console.log('Team set for governor')
}
export default func
func.tags = ['initial_dist']
func.id = 'initial_dist'