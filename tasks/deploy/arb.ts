import { task } from 'hardhat/config'
import arbConfig from './constants/arbConfig'
import arbTestnetConfig from './constants/arbConfig'
import arbHardhatConfig from './constants/arbHardhatConfig'

import optimismConfig from './constants/optimismConfig'
import testOptimismConfig from './constants/testOptimismConfig'

import fantomConfig from './constants/fantomConfig'
import testFantomConfig from './constants/testFantomConfig'

task('deploy:arb', 'Deploys Arbitrum contracts').setAction(async function (
  taskArguments,
  { ethers }
) {
  const mainnet = true

  const ARB_CONFIG = mainnet ? arbConfig : arbTestnetConfig
  const FTM_CONFIG = mainnet ? fantomConfig : testFantomConfig

  console.log(
    'ALCHEMY_MAINNET_ARBITRUM_API_KEY: ',
    process.env.ALCHEMY_MAINNET_ARBITRUM_API_KEY
  )

  // Load
  const [
    Flow,
    GaugeFactory,
    BribeFactory,
    PairFactory,
    Router,
    Library,
    VeArtProxy,
    VotingEscrow,
    RewardsDistributor,
    Voter,
    Minter,
    FlowGovernor,
    RedemptionReceiver,
    MerkleClaim
  ] = await Promise.all([
    ethers.getContractFactory('Flow'),
    ethers.getContractFactory('GaugeFactory'),
    ethers.getContractFactory('BribeFactory'),
    ethers.getContractFactory('PairFactory'),
    ethers.getContractFactory('Router'),
    ethers.getContractFactory('VelocimeterLibrary'),
    ethers.getContractFactory('VeArtProxy'),
    ethers.getContractFactory('VotingEscrow'),
    ethers.getContractFactory('RewardsDistributor'),
    ethers.getContractFactory('Voter'),
    ethers.getContractFactory('Minter'),
    ethers.getContractFactory('FlowGovernor'),
    ethers.getContractFactory('RedemptionReceiver'),
    ethers.getContractFactory('MerkleClaim')
  ])

  const flow = await Flow.deploy()
  await flow.deployed()
  console.log('Flow deployed to dunks: ', flow.address)

  const gaugeFactory = await GaugeFactory.deploy()
  await gaugeFactory.deployed()
  console.log('GaugeFactory deployed to: ', gaugeFactory.address)

  const bribeFactory = await BribeFactory.deploy()
  await bribeFactory.deployed()
  console.log('BribeFactory deployed to: ', bribeFactory.address)

  const pairFactory = await PairFactory.deploy()
  await pairFactory.deployed()
  console.log('PairFactory deployed to: ', pairFactory.address)

  const router = await Router.deploy(pairFactory.address, ARB_CONFIG.WETH)
  await router.deployed()
  console.log('Router deployed to: ', router.address)
  console.log('Args: ', pairFactory.address, ARB_CONFIG.WETH, '\n')

  const library = await Library.deploy(router.address)
  await library.deployed()
  console.log('VelocimeterLibrary deployed to: ', library.address)
  console.log('Args: ', router.address, '\n')

  const artProxy = await VeArtProxy.deploy()
  await artProxy.deployed()
  console.log('VeArtProxy deployed to: ', artProxy.address)

  const escrow = await VotingEscrow.deploy(flow.address, artProxy.address)
  await escrow.deployed()
  console.log('VotingEscrow deployed to: ', escrow.address)
  console.log('Args: ', flow.address, artProxy.address, '\n')

  const distributor = await RewardsDistributor.deploy(escrow.address)
  await distributor.deployed()
  console.log('RewardsDistributor deployed to: ', distributor.address)
  console.log('Args: ', escrow.address, '\n')

  const voter = await Voter.deploy(
    escrow.address,
    pairFactory.address,
    gaugeFactory.address,
    bribeFactory.address
  )
  await voter.deployed()
  console.log('Voter deployed to: ', voter.address)
  console.log(
    'Args: ',
    escrow.address,
    pairFactory.address,
    gaugeFactory.address,
    bribeFactory.address,
    '\n'
  )

  const minter = await Minter.deploy(
    voter.address,
    escrow.address,
    distributor.address
  )
  await minter.deployed()
  console.log('Minter deployed to: ', minter.address)
  console.log(
    'Args: ',
    voter.address,
    escrow.address,
    distributor.address,
    '\n'
  )

  const receiver = await RedemptionReceiver.deploy(
    ARB_CONFIG.USDC,
    flow.address,
    FTM_CONFIG.lzChainId,
    ARB_CONFIG.lzEndpoint
  )
  await receiver.deployed()
  console.log('RedemptionReceiver deployed to: ', receiver.address)
  console.log(
    'Args: ',
    ARB_CONFIG.USDC,
    flow.address,
    FTM_CONFIG.lzChainId,
    ARB_CONFIG.lzEndpoint,
    '\n'
  )

  const governor = await FlowGovernor.deploy(escrow.address)
  await governor.deployed()
  console.log('FlowGovernor deployed to: ', governor.address)
  console.log('Args: ', escrow.address, '\n')

  // Airdrop
  const claim = await MerkleClaim.deploy(flow.address, ARB_CONFIG.merkleRoot)
  await claim.deployed()
  console.log('MerkleClaim deployed to: ', claim.address)
  console.log('Args: ', flow.address, ARB_CONFIG.merkleRoot, '\n')

  // Initialize
  await flow.initialMint(ARB_CONFIG.teamEOA)
  console.log('Initial minted')

  await flow.setRedemptionReceiver(receiver.address)
  console.log('RedemptionReceiver set')

  await flow.setMerkleClaim(claim.address)
  console.log('MerkleClaim set')

  await flow.setMinter(minter.address)
  console.log('Minter set')

  await pairFactory.setPauser(ARB_CONFIG.teamMultisig)
  console.log('Pauser set')

  await escrow.setVoter(voter.address)
  console.log('Voter set')

  await escrow.setTeam(ARB_CONFIG.teamMultisig)
  console.log('Team set for escrow')

  await voter.setGovernor(ARB_CONFIG.teamMultisig)
  console.log('Governor set')

  await voter.setEmergencyCouncil(ARB_CONFIG.teamMultisig)
  console.log('Emergency Council set')

  await distributor.setDepositor(minter.address)
  console.log('Depositor set')

  await receiver.setTeam(ARB_CONFIG.teamMultisig)
  console.log('Team set for receiver')

  await governor.setTeam(ARB_CONFIG.teamMultisig)
  console.log('Team set for governor')

  // Whitelist
  const nativeToken = [flow.address]
  const tokenWhitelist = nativeToken.concat(ARB_CONFIG.tokenWhitelist)
  await voter.initialize(tokenWhitelist, minter.address)
  console.log('Whitelist set')

  // Initial veVELO distro
  await minter.initialize(
    ARB_CONFIG.partnerAddrs,
    ARB_CONFIG.partnerAmts,
    ARB_CONFIG.partnerMax
  )
  console.log('veVELO distributed')

  await minter.setTeam(ARB_CONFIG.teamMultisig)
  console.log('Team set for minter')

  console.log('Arbitrum contracts deployed')
})
