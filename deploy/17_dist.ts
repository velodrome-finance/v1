import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { DeployFunction } from 'hardhat-deploy/types'
// import * as tasks1 from 'tasks/deploy/arbHardhat'

import arbTestnetConfig from '../tasks/deploy/constants/arbTestnetConfig'
import arbConfig from '../tasks/deploy/constants/arbConfig'

const ARB_TEST_CONFIG = arbConfig

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { ethers } = hre
  const minter = await ethers.getContract('Minter')

  const { deployments, getNamedAccounts } = hre
  const { deploy } = deployments

  const { deployer } = await getNamedAccounts()

  const flow = await deployments.get('Flow')

  // Initial veVELO distro // this is not inside dist lets see if its being used for deploys??
  await minter.initialize(
    ARB_TEST_CONFIG.partnerAddrs,
    ARB_TEST_CONFIG.partnerAmts,
    ARB_TEST_CONFIG.partnerMax
  )
  console.log('veVELO not distributed yet') // we will run this when we want to start the epoch and have the NFTs
  //
  console.log('Arbitrum Goerli Velocimeter Instruments deployed')

  return true
  // Initialize

  console.log('deployer', deployer)

  // await flow.initialMint(ARB_CONFIG.teamEOA)
  // console.log('Initial minted')

  // await flow.setRedemptionReceiver(receiver.address)
  // console.log('RedemptionReceiver set')

  // await flow.setMerkleClaim(claim.address)
  // console.log('MerkleClaim set')

  // await flow.setMinter(minter.address)
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
