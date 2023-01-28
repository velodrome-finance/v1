import { task } from 'hardhat/config'
var fs = require('fs')

import optimismConfig from './constants/optimismConfig'
import testOptimismConfig from './constants/testOptimismConfig'
import arbTestnetConfig from './constants/arbConfig'

import fantomConfig from './constants/fantomConfig'
import testFantomConfig from './constants/testFantomConfig'

task('deploy:arbTest', 'Deploys Optimism contracts').setAction(async function (
  taskArguments,
  { ethers }
) {
  const mainnet = false

  const OP_CONFIG = mainnet ? optimismConfig : testOptimismConfig
  const FTM_CONFIG = mainnet ? fantomConfig : testFantomConfig

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

  //WIP wait for 5 block transactions to ensure deployment before verifying
  // https://stackoverflow.com/questions/72916701/hardhat-compile-deploy-and-verify-in-a-single-script
  // https://github.com/profullstackdeveloper/contract-deploy-verify-hardhat
  // shows how to save deployments and verify but for a single contract only... Need to find a better example to loop through them all save to /deployments and then verify...
  // await Promise.all.deployTransaction.wait(5)

  // //verify

  // await hre.run('verify:verify', {
  //   address: flow.address,
  //   contract: 'contracts/Flow.sol:MyContract', //Filename.sol:ClassName
  //   constructorArguments: [arg1, arg2, arg3]
  // })

  // WIP ^^

  const flow = await Flow.deploy()
  await flow.deployed()
  console.log('Flow deployed to: ', flow.address)

  await hre.run('verify:verify', {
    address: flow.address,
    contract: 'contracts/Flow.sol:Flow', //Filename.sol:ClassName
    constructorArguments: []
  })

  await flow.deployed()
  const name = await flow.name()
  console.log('dunksname: ', name)

  const temp1 = {
    [name]: flow.address
  }
  const json1 = JSON.stringify(temp1)
  console.log('result of json is ', json1)
  fs.writeFileSync('contracts/deployments/veloAddress.json', json1, err => {
    if (err) {
      console.log('ERROR! while creating file: ', err)
    } else {
      console.log('result is ', json1)
    }
  })

  // repeat for gauge factory
  // update all the things...

  const gaugeFactory = await GaugeFactory.deploy()
  await gaugeFactory.deployed()
  console.log('GaugeFactory deployed to: ', gaugeFactory.address)

  // await hre.run('verify:verify', {
  //   address: gaugeFactory.address,
  //   contract: 'contracts/factories/GaugeFactory.sol:GaugeFactory', //Filename.sol:ClassName
  //   constructorArguments: []
  // })

  // await gaugeFactory.deployed()
  // const name1 = await gaugeFactory.name()
  // console.log('dunksname: ', name)

  // const temp = {
  //   [name1]: gaugeFactory.address
  // }
  // const json = JSON.stringify(temp)
  // console.log('result of json is ', json)
  // fs.writeFileSync('contracts/deployments/veloAddress.json', json, err => {
  //   if (err) {
  //     console.log('ERROR! while creating file: ', err)
  //   } else {
  //     console.log('result is ', json)
  //   }
  // })

  const bribeFactory = await BribeFactory.deploy()
  await bribeFactory.deployed()
  console.log('BribeFactory deployed to: ', bribeFactory.address)

  const pairFactory = await PairFactory.deploy()
  await pairFactory.deployed()
  console.log('PairFactory deployed to: ', pairFactory.address)

  const router = await Router.deploy(pairFactory.address, OP_CONFIG.WETH)
  await router.deployed()
  console.log('Router deployed to: ', router.address)
  console.log('Args: ', pairFactory.address, OP_CONFIG.WETH, '\n')

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
    OP_CONFIG.USDC,
    flow.address,
    FTM_CONFIG.lzChainId,
    OP_CONFIG.lzEndpoint
  )
  await receiver.deployed()
  console.log('RedemptionReceiver deployed to: ', receiver.address)
  console.log(
    'Args: ',
    OP_CONFIG.USDC,
    flow.address,
    FTM_CONFIG.lzChainId,
    OP_CONFIG.lzEndpoint,
    '\n'
  )

  const governor = await FlowGovernor.deploy(escrow.address)
  await governor.deployed()
  console.log('FlowGovernor deployed to: ', governor.address)
  console.log('Args: ', escrow.address, '\n')

  // Airdrop
  // const claim = await MerkleClaim.deploy(flow.address, OP_CONFIG.merkleRoot)
  // await claim.deployed()
  // console.log('MerkleClaim deployed to: ', claim.address)
  // console.log('Args: ', flow.address, OP_CONFIG.merkleRoot, '\n')

  // Initialize
  await flow.initialMint(OP_CONFIG.teamEOA)
  console.log('Initial minted')

  await flow.setRedemptionReceiver(receiver.address)
  console.log('RedemptionReceiver set')

  // await flow.setMerkleClaim(claim.address)
  // console.log('MerkleClaim set')

  await flow.setMinter(minter.address)
  console.log('Minter set')

  await pairFactory.setPauser(OP_CONFIG.teamMultisig)
  console.log('Pauser set')

  await escrow.setVoter(voter.address)
  console.log(
    'Voter set',
    'voter address: ',
    voter.address,
    'escrow address: ',
    escrow.address
  )

  await escrow.setTeam(OP_CONFIG.teamMultisig)
  console.log('Team set for escrow')

  await voter.setGovernor(OP_CONFIG.teamMultisig)
  console.log('Governor set')

  await voter.setEmergencyCouncil(OP_CONFIG.teamMultisig)
  console.log('Emergency Council set')

  await distributor.setDepositor(minter.address)
  console.log('Depositor set')

  await receiver.setTeam(OP_CONFIG.teamMultisig)
  console.log('Team set for receiver')

  await governor.setTeam(OP_CONFIG.teamMultisig)
  console.log('Team set for governor')

  // Whitelist
  const nativeToken = [flow.address]
  const tokenWhitelist = nativeToken.concat(OP_CONFIG.tokenWhitelist)
  await voter.initialize(tokenWhitelist, minter.address)
  console.log('Whitelist set')

  // Initial veVELO distro
  await minter.initialize(
    OP_CONFIG.partnerAddrs,
    OP_CONFIG.partnerAmts,
    OP_CONFIG.partnerMax
  )
  console.log('veVELO distributed')

  await minter.setTeam(OP_CONFIG.teamMultisig)
  console.log('Team set for minter')

  console.log('Arbitrum Goerli Velocimeter Instruments deployed')
})
