import { task } from "hardhat/config";

import testConfluxConfig from "./constants/testConfluxConfig";


task("deploy:confluxTestnet", "Deploys confluxTestnet contracts").setAction(async function (
  taskArguments,
  { ethers }
) {

  const CONFLUX_CONFIG = testConfluxConfig;

  // Load
  const [
    Velo,
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
    VeloGovernor,
  ] = await Promise.all([
    ethers.getContractFactory("Velo"),
    ethers.getContractFactory("GaugeFactory"),
    ethers.getContractFactory("BribeFactory"),
    ethers.getContractFactory("PairFactory"),
    ethers.getContractFactory("Router"),
    ethers.getContractFactory("VelodromeLibrary"),
    ethers.getContractFactory("VeArtProxy"),
    ethers.getContractFactory("VotingEscrow"),
    ethers.getContractFactory("RewardsDistributor"),
    ethers.getContractFactory("Voter"),
    ethers.getContractFactory("Minter"),
    ethers.getContractFactory("VeloGovernor"),
  ]);

  const velo = await Velo.deploy();
  await velo.deployed();
  console.log("Velo deployed to: ", velo.address);

  const gaugeFactory = await GaugeFactory.deploy();
  await gaugeFactory.deployed();
  console.log("GaugeFactory deployed to: ", gaugeFactory.address);

  const bribeFactory = await BribeFactory.deploy();
  await bribeFactory.deployed();
  console.log("BribeFactory deployed to: ", bribeFactory.address);

  const pairFactory = await PairFactory.deploy();
  await pairFactory.deployed();
  console.log("PairFactory deployed to: ", pairFactory.address);

  const router = await Router.deploy(pairFactory.address, CONFLUX_CONFIG.WCFX);
  await router.deployed();
  console.log("Router deployed to: ", router.address);
  console.log("Args: ", pairFactory.address, CONFLUX_CONFIG.WCFX, "\n");

  const library = await Library.deploy(router.address);
  await library.deployed();
  console.log("VelodromeLibrary deployed to: ", library.address);
  console.log("Args: ", router.address, "\n");

  const artProxy = await VeArtProxy.deploy();
  await artProxy.deployed();
  console.log("VeArtProxy deployed to: ", artProxy.address);

  const escrow = await VotingEscrow.deploy(velo.address, artProxy.address);
  await escrow.deployed();
  console.log("VotingEscrow deployed to: ", escrow.address);
  console.log("Args: ", velo.address, artProxy.address, "\n");

  const distributor = await RewardsDistributor.deploy(escrow.address);
  await distributor.deployed();
  console.log("RewardsDistributor deployed to: ", distributor.address);
  console.log("Args: ", escrow.address, "\n");

  const voter = await Voter.deploy(
    escrow.address,
    pairFactory.address,
    gaugeFactory.address,
    bribeFactory.address
  );
  await voter.deployed();
  console.log("Voter deployed to: ", voter.address);
  console.log("Args: ", 
    escrow.address,
    pairFactory.address,
    gaugeFactory.address,
    bribeFactory.address,
    "\n"
  );

  const minter = await Minter.deploy(
    voter.address,
    escrow.address,
    distributor.address
  );
  await minter.deployed();
  console.log("Minter deployed to: ", minter.address);
  console.log("Args: ", 
    voter.address,
    escrow.address,
    distributor.address,
    "\n"
  );

//   const receiver = await RedemptionReceiver.deploy(
//     CONFLUX_CONFIG.USDC,
//     velo.address,
//     FTM_CONFIG.lzChainId,
//     CONFLUX_CONFIG.lzEndpoint,
//   );
//   await receiver.deployed();
//   console.log("RedemptionReceiver deployed to: ", receiver.address);
//   console.log("Args: ", 
//     CONFLUX_CONFIG.USDC,
//     velo.address,
//     FTM_CONFIG.lzChainId,
//     CONFLUX_CONFIG.lzEndpoint,
//     "\n"
//   );
//   await velo.setRedemptionReceiver(receiver.address);
//   console.log("RedemptionReceiver set");
// await receiver.setTeam(CONFLUX_CONFIG.teamMultisig)
// console.log("Team set for receiver");

  const governor = await VeloGovernor.deploy(escrow.address);
  await governor.deployed();
  console.log("VeloGovernor deployed to: ", governor.address);
  console.log("Args: ", escrow.address, "\n");

  // Initialize
  await velo.initialMint(CONFLUX_CONFIG.teamEOA);
  console.log("Initial minted");

  await velo.setMinter(minter.address);
  console.log("Minter set");

  await pairFactory.setPauser(CONFLUX_CONFIG.teamMultisig);
  console.log("Pauser set");

  await escrow.setVoter(voter.address);
  console.log("Voter set");

  await escrow.setTeam(CONFLUX_CONFIG.teamMultisig);
  console.log("Team set for escrow");

  await voter.setGovernor(CONFLUX_CONFIG.teamMultisig);
  console.log("Governor set");

  await voter.setEmergencyCouncil(CONFLUX_CONFIG.teamMultisig);
  console.log("Emergency Council set");

  await distributor.setDepositor(minter.address);
  console.log("Depositor set");

  await governor.setTeam(CONFLUX_CONFIG.teamMultisig)
  console.log("Team set for governor");

  // Whitelist
  const nativeToken = [velo.address];
  const tokenWhitelist = nativeToken.concat(CONFLUX_CONFIG.tokenWhitelist);
  await voter.initialize(tokenWhitelist, minter.address);
  console.log("Whitelist set");


  // Initial veVELO distro
  // await minter.initialize(
  //   CONFLUX_CONFIG.partnerAddrs,
  //   CONFLUX_CONFIG.partnerAmts,
  //   CONFLUX_CONFIG.partnerMax
  // );
  // console.log("veVELO distributed");

  // await minter.setTeam(CONFLUX_CONFIG.teamMultisig)
  // console.log("Team set for minter");
  
  console.log("conflux contracts deployed");
});
