import { task } from "hardhat/config";

import optimismConfig from "./constants/optimismConfig";
import testOptimismConfig from "./constants/testOptimismConfig";

task("deploy:op", "Deploys Optimism contracts").setAction(async function (
  taskArguments,
  { ethers }
) {
  const mainnet = false;

  const OP_CONFIG = mainnet ? optimismConfig : testOptimismConfig;

  // Load
  const [
    Velocimeter,
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
    ethers.getContractFactory("Velocimeter"),
    ethers.getContractFactory("GaugeFactory"),
    ethers.getContractFactory("BribeFactory"),
    ethers.getContractFactory("PairFactory"),
    ethers.getContractFactory("Router"),
    ethers.getContractFactory("VelocimeterLibrary"),
    ethers.getContractFactory("VeArtProxy"),
    ethers.getContractFactory("VotingEscrow"),
    ethers.getContractFactory("RewardsDistributor"),
    ethers.getContractFactory("Voter"),
    ethers.getContractFactory("Minter"),
    ethers.getContractFactory("VeloGovernor"),
  ]);

  const flow = await Velocimeter.deploy();
  await flow.deployed();
  console.log("FLOW deployed to: ", flow.address);

  const gaugeFactory = await GaugeFactory.deploy();
  await gaugeFactory.deployed();
  console.log("GaugeFactory deployed to: ", gaugeFactory.address);

  const bribeFactory = await BribeFactory.deploy();
  await bribeFactory.deployed();
  console.log("BribeFactory deployed to: ", bribeFactory.address);

  const pairFactory = await PairFactory.deploy();
  await pairFactory.deployed();
  console.log("PairFactory deployed to: ", pairFactory.address);

  const router = await Router.deploy(pairFactory.address, OP_CONFIG.WETH);
  await router.deployed();
  console.log("Router deployed to: ", router.address);
  console.log("Args: ", pairFactory.address, OP_CONFIG.WETH, "\n");

  const library = await Library.deploy(router.address);
  await library.deployed();
  console.log("VelocimeterLibrary deployed to: ", library.address);
  console.log("Args: ", router.address, "\n");

  const artProxy = await VeArtProxy.deploy();
  await artProxy.deployed();
  console.log("VeArtProxy deployed to: ", artProxy.address);

  const escrow = await VotingEscrow.deploy(flow.address, artProxy.address);
  await escrow.deployed();
  console.log("VotingEscrow deployed to: ", escrow.address);
  console.log("Args: ", flow.address, artProxy.address, "\n");

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

  const governor = await VeloGovernor.deploy(escrow.address);
  await governor.deployed();
  console.log("VeloGovernor deployed to: ", governor.address);
  console.log("Args: ", escrow.address, "\n");

  // Airdrop
  // Initialize
  await flow.setMinter(minter.address);
  console.log("Minter set");

  await pairFactory.setPauser(OP_CONFIG.teamMultisig);
  console.log("Pauser set");

  await escrow.setVoter(voter.address);
  console.log("Voter set");

  await escrow.setTeam(OP_CONFIG.teamMultisig);
  console.log("Team set for escrow");

  await voter.setGovernor(OP_CONFIG.teamMultisig);
  console.log("Governor set");

  await voter.setEmergencyCouncil(OP_CONFIG.teamMultisig);
  console.log("Emergency Council set");

  await distributor.setDepositor(minter.address);
  console.log("Depositor set");

  await governor.setTeam(OP_CONFIG.teamMultisig)
  console.log("Team set for governor");

  // Whitelist
  const nativeToken = [flow.address];
  const tokenWhitelist = nativeToken.concat(OP_CONFIG.tokenWhitelist);
  await voter.initialize(tokenWhitelist, minter.address);
  console.log("Whitelist set");

  // Initial veFLOW distro
  await minter.initialize(
    OP_CONFIG.partnerAddrs,
    OP_CONFIG.partnerAmts,
    OP_CONFIG.partnerMax
  );
  console.log("veFLOW distributed");

  await minter.setTeam(OP_CONFIG.teamMultisig)
  console.log("Team set for minter");

  console.log("Optimism contracts deployed");
});
