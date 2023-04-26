pragma solidity 0.8.13;

import './BaseTest.sol';

contract ExternalBribesTest is BaseTest {
    VotingEscrow escrow;
    GaugeFactory gaugeFactory;
    BribeFactory bribeFactory;
    Voter voter;
    RewardsDistributor distributor;
    Minter minter;
    Gauge gauge;
    InternalBribe bribe;
    ExternalBribe xbribe;

    function setUp() public {
        vm.warp(block.timestamp + 1 weeks); // put some initial time in

        deployOwners();
        deployCoins();
        mintStables();
        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 2e25;
        amounts[1] = 1e25;
        amounts[2] = 1e25;
        mintVelo(owners, amounts);
        mintLR(owners, amounts);
        VeArtProxy artProxy = new VeArtProxy();
        escrow = new VotingEscrow(address(VELO), address(artProxy));
        deployPairFactoryAndRouter();
        deployPairWithOwner(address(owner));

        // deployVoter()
        gaugeFactory = new GaugeFactory();
        bribeFactory = new BribeFactory();
        voter = new Voter(address(escrow), address(factory), address(gaugeFactory), address(bribeFactory));

        escrow.setVoter(address(voter));

        // deployMinter()
        distributor = new RewardsDistributor(address(escrow));
        minter = new Minter(address(voter), address(escrow), address(distributor));
        distributor.setDepositor(address(minter));
        VELO.setMinter(address(minter));
        address[] memory tokens = new address[](5);
        tokens[0] = address(USDC);
        tokens[1] = address(FRAX);
        tokens[2] = address(DAI);
        tokens[3] = address(VELO);
        tokens[4] = address(LR);
        voter.initialize(tokens, address(minter));

        address[] memory claimants = new address[](0);
        uint[] memory amounts1 = new uint[](0);
        minter.initialize(claimants, amounts1, 0);

        // USDC - FRAX stable
        gauge = Gauge(voter.createGauge(address(pair)));
        bribe = InternalBribe(gauge.internal_bribe());
        xbribe = ExternalBribe(gauge.external_bribe());

        // ve
        VELO.approve(address(escrow), TOKEN_1);
        escrow.create_lock(TOKEN_1, 365 * 86400);

        vm.startPrank(address(owner2));
        VELO.approve(address(escrow), TOKEN_1);
        escrow.create_lock(TOKEN_1, 365 * 86400);
        vm.stopPrank();

        vm.startPrank(address(owner3));
        VELO.approve(address(escrow), TOKEN_1);
        escrow.create_lock(TOKEN_1, 365 * 86400);
        vm.stopPrank();

        vm.warp(block.timestamp + 1);
    }

    function testCanClaimExternalBribe() public {
        // fwd half a week
        vm.warp(block.timestamp + 1 weeks / 2);

        // create a bribe
        LR.approve(address(xbribe), TOKEN_1);
        xbribe.notifyRewardAmount(address(LR), TOKEN_1);
        assertEq(LR.balanceOf(address(xbribe)), TOKEN_1);

        // vote
        address[] memory pools = new address[](1);
        pools[0] = address(pair);
        uint256[] memory weights = new uint256[](1);
        weights[0] = 10000;
        voter.vote(1, pools, weights);

        // rewards
        address[] memory rewards = new address[](1);
        rewards[0] = address(LR);

        // cannot claim
        uint256 pre = LR.balanceOf(address(owner));
        vm.prank(address(voter));
        xbribe.getRewardForOwner(1, rewards);
        uint256 post = LR.balanceOf(address(owner));
        assertEq(post - pre, 0);

        // fwd half a week
        vm.warp(block.timestamp + 1 weeks / 2);

        // deliver bribe
        pre = LR.balanceOf(address(owner));
        vm.prank(address(voter));
        xbribe.getRewardForOwner(1, rewards);
        post = LR.balanceOf(address(owner));
        assertEq(post - pre, TOKEN_1);
    }

    function testCanClaimExternalBribeProRata() public {
        // fwd half a week
        vm.warp(block.timestamp + 1 weeks / 2);

        // create a bribe
        LR.approve(address(xbribe), TOKEN_1);
        xbribe.notifyRewardAmount(address(LR), TOKEN_1);
        assertEq(LR.balanceOf(address(xbribe)), TOKEN_1);

        // vote
        address[] memory pools = new address[](1);
        pools[0] = address(pair);
        uint256[] memory weights = new uint256[](1);
        weights[0] = 10000;
        voter.vote(1, pools, weights);

        vm.startPrank(address(owner2));
        voter.vote(2, pools, weights);
        vm.stopPrank();

        // rewards
        address[] memory rewards = new address[](1);
        rewards[0] = address(LR);

        // fwd half a week
        vm.warp(block.timestamp + 1 weeks / 2);

        // deliver bribe
        uint256 pre = LR.balanceOf(address(owner));
        vm.prank(address(voter));
        xbribe.getRewardForOwner(1, rewards);
        uint256 post = LR.balanceOf(address(owner));
        assertEq(post - pre, TOKEN_1 / 2);

        pre = LR.balanceOf(address(owner2));
        vm.prank(address(voter));
        xbribe.getRewardForOwner(2, rewards);
        post = LR.balanceOf(address(owner2));
        assertEq(post - pre, TOKEN_1 / 2);
    }
    
    function testCanClaimExternalBribeProRataAfterManyWeeks() public {
        // fwd half a week
        vm.warp(block.timestamp + 1 weeks / 2);

        // create a bribe with some rewards
        LR.approve(address(xbribe), TOKEN_1 * 10);
        xbribe.notifyRewardAmount(address(LR), TOKEN_1);
        assertEq(LR.balanceOf(address(xbribe)), TOKEN_1);

        uint256 initialBalance2 = LR.balanceOf(address(owner2));
        uint256 initialBalance3 = LR.balanceOf(address(owner3));

        // owner2 and owner3 vote
        address[] memory pools = new address[](1);
        pools[0] = address(pair);
        uint256[] memory weights = new uint256[](1);
        weights[0] = 10000;

        vm.prank(address(owner2));
        voter.vote(2, pools, weights);

        vm.prank(address(owner3));
        voter.vote(3, pools, weights);

        // fwd 1 week
        vm.warp(block.timestamp + 1 weeks);

        // hand out some more rewards
        xbribe.notifyRewardAmount(address(LR), TOKEN_1);
        assertEq(LR.balanceOf(address(xbribe)), TOKEN_1 * 2);

        // vote again
        vm.prank(address(owner2));
        voter.vote(2, pools, weights);

        vm.prank(address(owner3));
        voter.vote(3, pools, weights);

        // fwd 3 weeks
        vm.warp(block.timestamp + 3 weeks);
    
        // claim bribe
        address[] memory rewards = new address[](1);
        rewards[0] = address(LR);

        vm.prank(address(voter));
        xbribe.getRewardForOwner(2, rewards);
        uint256 post = LR.balanceOf(address(owner2));
        assertEq(post - initialBalance2, TOKEN_1);

        vm.prank(address(voter));
        xbribe.getRewardForOwner(3, rewards);
        post = LR.balanceOf(address(owner3));
        assertEq(post - initialBalance3, TOKEN_1);
    }

    function testCanClaimExternalBribeProRataAfterManyWeeks2() public {
        // fwd half a week
        vm.warp(block.timestamp + 1 weeks / 2);

        // create a bribe with some rewards
        LR.approve(address(xbribe), TOKEN_1 * 10);
        xbribe.notifyRewardAmount(address(LR), TOKEN_1);
        assertEq(LR.balanceOf(address(xbribe)), TOKEN_1);

        uint256 initialBalance2 = LR.balanceOf(address(owner2));
        uint256 initialBalance3 = LR.balanceOf(address(owner3));

        // owner2 and owner3 vote
        address[] memory pools = new address[](1);
        pools[0] = address(pair);
        uint256[] memory weights = new uint256[](1);
        weights[0] = 10000;

        vm.prank(address(owner2));
        voter.vote(2, pools, weights);

        vm.prank(address(owner3));
        voter.vote(3, pools, weights);

        // fwd 1 week
        vm.warp(block.timestamp + 1 weeks);

        // hand out some more rewards
        xbribe.notifyRewardAmount(address(LR), TOKEN_1);
        assertEq(LR.balanceOf(address(xbribe)), TOKEN_1 * 2);

        // vote again
        vm.prank(address(owner2));
        voter.vote(2, pools, weights);

        vm.prank(address(owner3));
        voter.vote(3, pools, weights);

        // fwd 3 weeks
        vm.warp(block.timestamp + 3 weeks);

        // hand out some more rewards
        xbribe.notifyRewardAmount(address(LR), TOKEN_1 * 2);
        assertEq(LR.balanceOf(address(xbribe)), TOKEN_1 * 4);

        // vote again
        vm.prank(address(owner2));
        voter.vote(2, pools, weights);

        vm.prank(address(owner3));
        voter.vote(3, pools, weights);

        // fwd 3 weeks
        vm.warp(block.timestamp + 3 weeks);

        // claim bribe
        address[] memory rewards = new address[](1);
        rewards[0] = address(LR);

        vm.prank(address(voter));
        xbribe.getRewardForOwner(2, rewards);
        uint256 post = LR.balanceOf(address(owner2));
        assertEq(post - initialBalance2, TOKEN_1 * 2);

        vm.prank(address(voter));
        xbribe.getRewardForOwner(3, rewards);
        post = LR.balanceOf(address(owner3));
        assertEq(post - initialBalance3, TOKEN_1 * 2);
    }
    
    function testCanClaimExternalBribeProRataEveryWeek() public {
        // fwd half a week
        vm.warp(block.timestamp + 1 weeks / 2);

        // create a bribe with some rewards
        LR.approve(address(xbribe), TOKEN_1 * 10);
        xbribe.notifyRewardAmount(address(LR), TOKEN_1);
        assertEq(LR.balanceOf(address(xbribe)), TOKEN_1);

        uint256 initialBalance2 = LR.balanceOf(address(owner2));
        uint256 initialBalance3 = LR.balanceOf(address(owner3));

        // owner2 and owner3 vote
        address[] memory pools = new address[](1);
        pools[0] = address(pair);
        uint256[] memory weights = new uint256[](1);
        weights[0] = 10000;

        vm.prank(address(owner2));
        voter.vote(2, pools, weights);

        vm.prank(address(owner3));
        voter.vote(3, pools, weights);

        // fwd 1 week
        vm.warp(block.timestamp + 1 weeks);

        // claim bribe
        address[] memory rewards = new address[](1);
        rewards[0] = address(LR);
        
        vm.prank(address(voter));
        xbribe.getRewardForOwner(2, rewards);
        uint256 post = LR.balanceOf(address(owner2));
        assertEq(post - initialBalance2, TOKEN_1 / 2);

        vm.prank(address(voter));
        xbribe.getRewardForOwner(3, rewards);
        post = LR.balanceOf(address(owner3));
        assertEq(post - initialBalance3, TOKEN_1 / 2);

        // hand out some more rewards
        xbribe.notifyRewardAmount(address(LR), TOKEN_1);
        assertEq(LR.balanceOf(address(xbribe)), TOKEN_1);

        // vote again
        vm.prank(address(owner2));
        voter.vote(2, pools, weights);

        vm.prank(address(owner3));
        voter.vote(3, pools, weights);

        // fwd 1 week
        vm.warp(block.timestamp + 1 weeks);

        // claim bribe
        vm.prank(address(voter));
        xbribe.getRewardForOwner(2, rewards);
        post = LR.balanceOf(address(owner2));
        assertEq(post - initialBalance2, TOKEN_1);

        vm.prank(address(voter));
        xbribe.getRewardForOwner(3, rewards);
        post = LR.balanceOf(address(owner3));
        assertEq(post - initialBalance3, TOKEN_1);
    }

    function testCanClaimExternalBribeStaggered() public {
        // fwd half a week
        vm.warp(block.timestamp + 1 weeks / 2);

        // create a bribe
        LR.approve(address(xbribe), TOKEN_1);
        xbribe.notifyRewardAmount(address(LR), TOKEN_1);
        assertEq(LR.balanceOf(address(xbribe)), TOKEN_1);

        // vote
        address[] memory pools = new address[](1);
        pools[0] = address(pair);
        uint256[] memory weights = new uint256[](1);
        weights[0] = 10000;
        voter.vote(1, pools, weights);

        // vote delayed
        vm.warp(block.timestamp + 1 days);
        vm.startPrank(address(owner2));
        voter.vote(2, pools, weights);
        vm.stopPrank();

        // rewards
        address[] memory rewards = new address[](1);
        rewards[0] = address(LR);

        // fwd
        vm.warp(block.timestamp + 1 weeks / 2);

        // deliver bribe
        uint256 pre = LR.balanceOf(address(owner));
        vm.prank(address(voter));
        xbribe.getRewardForOwner(1, rewards);
        uint256 post = LR.balanceOf(address(owner));
        assertGt(post - pre, TOKEN_1 / 2); // 500172176312657261
        uint256 diff = post - pre;

        pre = LR.balanceOf(address(owner2));
        vm.prank(address(voter));
        xbribe.getRewardForOwner(2, rewards);
        post = LR.balanceOf(address(owner2));
        assertLt(post - pre, TOKEN_1 / 2); // 499827823687342738
        uint256 diff2 = post - pre;

        assertEq(diff + diff2, TOKEN_1 - 1); // -1 for rounding
    }
    
    // Verify the knwon issue of Velodrom is fixed: users can claim eligible rewards from ExternalBribe contracts more than once
    // https://github.com/velodrome-finance/docs/blob/main/pages/security.md
    function testCanOnlyClaimOnce() public {
        vm.warp(block.timestamp + 1 weeks / 2);

        // create a bribe
        LR.approve(address(xbribe), TOKEN_1);
        xbribe.notifyRewardAmount(address(LR), TOKEN_1);

        // vote
        address[] memory pools = new address[](1);
        pools[0] = address(pair);
        uint256[] memory weights = new uint256[](1);
        weights[0] = 10000;
        voter.vote(1, pools, weights);

        vm.startPrank(address(owner2));
        voter.vote(2, pools, weights);
        vm.stopPrank();

        // fwd half a week
        vm.warp(block.timestamp + 1 weeks / 2);

        uint256 pre = LR.balanceOf(address(owner));
        uint256 earned = xbribe.earned(address(LR), 1);
        assertEq(earned, TOKEN_1 / 2);

        // rewards
        address[] memory rewards = new address[](1);
        rewards[0] = address(LR);

        vm.startPrank(address(voter));
        // once
        xbribe.getRewardForOwner(1, rewards);
        uint256 post = LR.balanceOf(address(owner));
        // twice
        xbribe.getRewardForOwner(1, rewards);
        vm.stopPrank();

        uint256 post_post = LR.balanceOf(address(owner));
        assertEq(post_post, post);
        assertEq(post_post - pre, TOKEN_1 / 2);
    }
    
    function testCanClaimOnlyOnceArray() public {
        vm.warp(block.timestamp + 1 weeks / 2);

        // create a bribe
        LR.approve(address(xbribe), TOKEN_1);
        xbribe.notifyRewardAmount(address(LR), TOKEN_1);

        // vote
        address[] memory pools = new address[](1);
        pools[0] = address(pair);
        uint256[] memory weights = new uint256[](1);
        weights[0] = 10000;
        voter.vote(1, pools, weights);

        vm.startPrank(address(owner2));
        voter.vote(2, pools, weights);
        vm.stopPrank();

        // fwd half a week
        vm.warp(block.timestamp + 1 weeks / 2);

        uint256 pre = LR.balanceOf(address(owner));
        uint256 earned = xbribe.earned(address(LR), 1);
        assertEq(earned, TOKEN_1 / 2);

        // rewards
        address[] memory rewards = new address[](2);
        rewards[0] = address(LR);
        rewards[1] = address(LR);

        vm.startPrank(address(voter));
        // once
        xbribe.getRewardForOwner(1, rewards);
        uint256 post = LR.balanceOf(address(owner));
        // twice
        xbribe.getRewardForOwner(1, rewards);
        vm.stopPrank();

        uint256 post_post = LR.balanceOf(address(owner));
        assertEq(post_post, post);
        assertEq(post_post - pre, TOKEN_1 / 2);
    }
}
