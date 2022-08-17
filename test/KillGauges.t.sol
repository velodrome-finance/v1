pragma solidity 0.8.13;

import "./BaseTest.sol";

contract KillGaugesTest is BaseTest {
  VotingEscrow escrow;
  GaugeFactory gaugeFactory;
  BribeFactory bribeFactory;
  Voter voter;
  RewardsDistributor distributor;
  Minter minter;
  TestStakingRewards staking;
  TestStakingRewards staking2;
  Gauge gauge;
  Gauge gauge2;
  InternalBribe bribe;
  InternalBribe bribe2;

  function setUp() public {
    deployOwners();
    deployCoins();
    mintStables();
    uint256[] memory amounts = new uint256[](3);
    amounts[0] = 2e25;
    amounts[1] = 1e25;
    amounts[2] = 1e25;
    mintVelo(owners, amounts);
    VeArtProxy artProxy = new VeArtProxy();
    escrow = new VotingEscrow(address(VELO), address(artProxy));

    VELO.approve(address(escrow), 100 * TOKEN_1);
    escrow.create_lock(100 * TOKEN_1, 4 * 365 * 86400);
    vm.roll(block.number + 1);

    deployPairFactoryAndRouter();

    deployPairWithOwner(address(owner));

    gaugeFactory = new GaugeFactory();
    bribeFactory = new BribeFactory();
    voter = new Voter(
      address(escrow),
      address(factory),
      address(gaugeFactory),
      address(bribeFactory)
    );

    escrow.setVoter(address(voter));

    distributor = new RewardsDistributor(address(escrow));

    minter = new Minter(address(voter), address(escrow), address(distributor));
    distributor.setDepositor(address(minter));
    VELO.setMinter(address(minter));
    address[] memory tokens = new address[](4);
    tokens[0] = address(USDC);
    tokens[1] = address(FRAX);
    tokens[2] = address(DAI);
    tokens[3] = address(VELO);
    voter.initialize(tokens, address(minter));

    VELO.approve(address(gaugeFactory), 15 * TOKEN_100K);
    voter.createGauge(address(pair));
    voter.createGauge(address(pair2));

    staking = new TestStakingRewards(address(pair), address(VELO));
    staking2 = new TestStakingRewards(address(pair2), address(VELO));

    address gaugeAddress = voter.gauges(address(pair));
    address bribeAddress = voter.internal_bribes(gaugeAddress);

    gauge = Gauge(gaugeAddress);
    bribe = InternalBribe(bribeAddress);

    address gaugeAddress2 = voter.gauges(address(pair2));
    address bribeAddress2 = voter.internal_bribes(gaugeAddress2);

    gauge2 = Gauge(gaugeAddress2);
    bribe2 = InternalBribe(bribeAddress2);
  }

  function testEmergencyCouncilCanKillAndReviveGauges() public {
    address gaugeAddress = address(gauge);

    // emergency council is owner
    voter.killGauge(gaugeAddress);
    assertFalse(voter.isAlive(gaugeAddress));

    voter.reviveGauge(gaugeAddress);
    assertTrue(voter.isAlive(gaugeAddress));
  }

  function testFailCouncilCannotKillNonExistentGauge() public {
    voter.killGauge(address(0xDEAD));
  }

  function testFailNoOneElseCanKillGauges() public {
    address gaugeAddress = address(gauge);
    vm.prank(address(owner2));
    voter.killGauge(gaugeAddress);
  }

  function testKilledGaugeCannotDeposit() public {
    USDC.approve(address(router), USDC_100K);
    FRAX.approve(address(router), TOKEN_100K);
    router.addLiquidity(address(FRAX), address(USDC), true, TOKEN_100K, USDC_100K, TOKEN_100K, USDC_100K, address(owner), block.timestamp);

    address gaugeAddress = address(gauge);
    voter.killGauge(gaugeAddress);

    uint256 supply = pair.balanceOf(address(owner));
    pair.approve(address(gauge), supply);
    vm.expectRevert(abi.encodePacked(""));
    gauge.deposit(supply, 1);
  }

  function testKilledGaugeCanWithdraw() public {
    USDC.approve(address(router), USDC_100K);
    FRAX.approve(address(router), TOKEN_100K);
    router.addLiquidity(address(FRAX), address(USDC), true, TOKEN_100K, USDC_100K, TOKEN_100K, USDC_100K, address(owner), block.timestamp);

    address gaugeAddress = address(gauge);

    uint256 supply = pair.balanceOf(address(owner));
    pair.approve(address(gauge), supply);
    gauge.deposit(supply, 1);

    voter.killGauge(gaugeAddress);

    gauge.withdrawToken(supply, 1); // should be allowed
  }

  function testKilledGaugeCanUpdateButGoesToZero() public {
    vm.warp(block.timestamp + 86400 * 7 * 2);
    vm.roll(block.number + 1);
    minter.update_period();
    voter.updateGauge(address(gauge));
    uint256 claimable = voter.claimable(address(gauge));
    VELO.approve(address(staking), claimable);
    staking.notifyRewardAmount(claimable);
    address[] memory gauges = new address[](1);
    gauges[0] = address(gauge);
    
    voter.killGauge(address(gauge));

    voter.updateFor(gauges);

    assertEq(voter.claimable(address(gauge)), 0);
  }

  function testKilledGaugeCanDistributeButGoesToZero() public {
    vm.warp(block.timestamp + 86400 * 7 * 2);
    vm.roll(block.number + 1);
    minter.update_period();
    voter.updateGauge(address(gauge));
    uint256 claimable = voter.claimable(address(gauge));
    VELO.approve(address(staking), claimable);
    staking.notifyRewardAmount(claimable);
    address[] memory gauges = new address[](1);
    gauges[0] = address(gauge);
    voter.updateFor(gauges);

    voter.killGauge(address(gauge));

    assertEq(voter.claimable(address(gauge)), 0);
  }

  function testCanStillDistroAllWithKilledGauge() public {
    vm.warp(block.timestamp + 86400 * 7 * 2);
    vm.roll(block.number + 1);
    minter.update_period();
    voter.updateGauge(address(gauge));
    voter.updateGauge(address(gauge2));

    uint256 claimable = voter.claimable(address(gauge));
    console2.log(claimable);
    VELO.approve(address(staking), claimable);
    staking.notifyRewardAmount(claimable);

    uint256 claimable2 = voter.claimable(address(gauge2));
    VELO.approve(address(staking), claimable2);
    staking.notifyRewardAmount(claimable2);

    address[] memory gauges = new address[](2);
    gauges[0] = address(gauge);
    gauges[1] = address(gauge2);
    voter.updateFor(gauges);

    voter.killGauge(address(gauge));

    // should be able to claim from gauge2, just not from gauge
    voter.distro();
  }
}
