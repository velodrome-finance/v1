// 1:1 with Hardhat test
pragma solidity 0.8.13;

import './BaseTest.sol';

contract PairTest is BaseTest {
    VotingEscrow escrow;
    GaugeFactory gaugeFactory;
    BribeFactory bribeFactory;
    Voter voter;
    RewardsDistributor distributor;
    Minter minter;
    TestStakingRewards staking;
    Gauge gauge;
    Gauge gauge2;
    Gauge gauge3;
    InternalBribe bribe;
    ExternalBribe xbribe;
    InternalBribe bribe2;
    InternalBribe bribe3;

    function deployPairCoins() public {
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
    }

    function createLock() public {
        deployPairCoins();

        VELO.approve(address(escrow), 5e17);
        escrow.create_lock(5e17, 4 * 365 * 86400);
        vm.roll(block.number + 1); // fwd 1 block because escrow.balanceOfNFT() returns 0 in same block
        assertGt(escrow.balanceOfNFT(1), 495063075414519385);
        assertEq(VELO.balanceOf(address(escrow)), 5e17);
    }

    function increaseLock() public {
        createLock();

        VELO.approve(address(escrow), 5e17);
        escrow.increase_amount(1, 5e17);
        vm.expectRevert(abi.encodePacked('Can only increase lock duration'));
        escrow.increase_unlock_time(1, 4 * 365 * 86400);
        assertGt(escrow.balanceOfNFT(1), 995063075414519385);
        assertEq(VELO.balanceOf(address(escrow)), TOKEN_1);
    }

    function votingEscrowViews() public {
        increaseLock();
        
        uint256 block_ = escrow.block_number();
        assertEq(escrow.balanceOfAtNFT(1, block_), escrow.balanceOfNFT(1));
        assertEq(escrow.totalSupplyAt(block_), escrow.totalSupply());

        assertGt(escrow.balanceOfNFT(1), 995063075414519385);
        assertEq(VELO.balanceOf(address(escrow)), TOKEN_1);
    }

    function stealNFT() public {
        votingEscrowViews();

        vm.expectRevert(abi.encodePacked(''));
        owner2.transferFrom(address(escrow), address(owner), address(owner2), 1);
        vm.expectRevert(abi.encodePacked(''));
        owner2.approveEscrow(address(escrow), address(owner2), 1);
        vm.expectRevert(abi.encodePacked(''));
        owner2.merge(address(escrow), 1, 2);
    }

    function votingEscrowMerge() public {
        stealNFT();

        VELO.approve(address(escrow), TOKEN_1);
        escrow.create_lock(TOKEN_1, 4 * 365 * 86400);
        assertGt(escrow.balanceOfNFT(2), 995063075414519385);
        assertEq(VELO.balanceOf(address(escrow)), 2 * TOKEN_1);
        console2.log(escrow.totalSupply());
        escrow.merge(2, 1);
        console2.log(escrow.totalSupply());
        assertGt(escrow.balanceOfNFT(1), 1990063075414519385);
        assertEq(escrow.balanceOfNFT(2), 0);
        (int256 id, uint256 amount) = escrow.locked(2);
        assertEq(amount, 0);
        assertEq(escrow.ownerOf(2), address(0));
        VELO.approve(address(escrow), TOKEN_1);
        escrow.create_lock(TOKEN_1, 4 * 365 * 86400);
        assertGt(escrow.balanceOfNFT(3), 995063075414519385);
        assertEq(VELO.balanceOf(address(escrow)), 3 * TOKEN_1);
        console2.log(escrow.totalSupply());
        escrow.merge(3, 1);
        console2.log(escrow.totalSupply());
        assertGt(escrow.balanceOfNFT(1), 1990063075414519385);
        assertEq(escrow.balanceOfNFT(3), 0);
        (id, amount) = escrow.locked(3);
        assertEq(amount, 0);
        assertEq(escrow.ownerOf(3), address(0));
    }

    function confirmUsdcDeployment() public {
        votingEscrowMerge();

        assertEq(USDC.name(), "USDC");
    }

    function confirmFraxDeployment() public {
        confirmUsdcDeployment();

        assertEq(FRAX.name(), "FRAX");
    }

    function confirmTokensForFraxUsdc() public {
        confirmFraxDeployment();
        deployPairFactoryAndRouter();
        deployPairWithOwner(address(owner));
        deployPairWithOwner(address(owner2));

        (address token0, address token1) = router.sortTokens(address(USDC), address(FRAX));
        assertEq(pair.token0(), token0);
        assertEq(pair.token1(), token1);
    }

    function mintAndBurnTokensForPairFraxUsdc() public {
        confirmTokensForFraxUsdc();

        USDC.transfer(address(pair), USDC_1);
        FRAX.transfer(address(pair), TOKEN_1);
        pair.mint(address(owner));
        assertEq(pair.getAmountOut(USDC_1, address(USDC)), 982117769725505988);
        (uint256 amount, bool stable) = router.getAmountOut(USDC_1, address(USDC), address(FRAX));
        assertEq(pair.getAmountOut(USDC_1, address(USDC)), amount);
        assertTrue(stable);
        assertTrue(router.isPair(address(pair)));
    }

    function mintAndBurnTokensForPairFraxUsdcOwner2() public {
        mintAndBurnTokensForPairFraxUsdc();

        owner2.transfer(address(USDC), address(pair), USDC_1);
        owner2.transfer(address(FRAX), address(pair), TOKEN_1);
        owner2.mint(address(pair), address(owner2));
        assertEq(owner2.getAmountOut(address(pair), USDC_1, address(USDC)), 992220948146798746);
    }

    function routerAddLiquidity() public {
        mintAndBurnTokensForPairFraxUsdcOwner2();

        USDC.approve(address(router), USDC_100K);
        FRAX.approve(address(router), TOKEN_100K);
        router.addLiquidity(address(FRAX), address(USDC), true, TOKEN_100K, USDC_100K, TOKEN_100K, USDC_100K, address(owner), block.timestamp);
        USDC.approve(address(router), USDC_100K);
        FRAX.approve(address(router), TOKEN_100K);
        router.addLiquidity(address(FRAX), address(USDC), false, TOKEN_100K, USDC_100K, TOKEN_100K, USDC_100K, address(owner), block.timestamp);
        DAI.approve(address(router), TOKEN_100M);
        FRAX.approve(address(router), TOKEN_100M);
        router.addLiquidity(address(FRAX), address(DAI), true, TOKEN_100M, TOKEN_100M, 0, 0, address(owner), block.timestamp);
    }

    function routerRemoveLiquidity() public {
        routerAddLiquidity();

        USDC.approve(address(router), USDC_100K);
        FRAX.approve(address(router), TOKEN_100K);
        router.quoteAddLiquidity(address(FRAX), address(USDC), true, TOKEN_100K, USDC_100K);
        router.quoteRemoveLiquidity(address(FRAX), address(USDC), true, USDC_100K);
    }

    function routerAddLiquidityOwner2() public {
        routerRemoveLiquidity();

        owner2.approve(address(USDC), address(router), USDC_100K);
        owner2.approve(address(FRAX), address(router), TOKEN_100K);
        owner2.addLiquidity(payable(address(router)), address(FRAX), address(USDC), true, TOKEN_100K, USDC_100K, TOKEN_100K, USDC_100K, address(owner2), block.timestamp);
        owner2.approve(address(USDC), address(router), USDC_100K);
        owner2.approve(address(FRAX), address(router), TOKEN_100K);
        owner2.addLiquidity(payable(address(router)), address(FRAX), address(USDC), false, TOKEN_100K, USDC_100K, TOKEN_100K, USDC_100K, address(owner2), block.timestamp);
        owner2.approve(address(DAI), address(router), TOKEN_100M);
        owner2.approve(address(FRAX), address(router), TOKEN_100M);
        owner2.addLiquidity(payable(address(router)), address(FRAX), address(DAI), true, TOKEN_100M, TOKEN_100M, 0, 0, address(owner2), block.timestamp);
    }

    function routerPair1GetAmountsOutAndSwapExactTokensForTokens() public {
        routerAddLiquidityOwner2();

        Router.route[] memory routes = new Router.route[](1);
        routes[0] = Router.route(address(USDC), address(FRAX), true);

        assertEq(router.getAmountsOut(USDC_1, routes)[1], pair.getAmountOut(USDC_1, address(USDC)));

        uint256[] memory assertedOutput = router.getAmountsOut(USDC_1, routes);
        USDC.approve(address(router), USDC_1);
        router.swapExactTokensForTokens(USDC_1, assertedOutput[1], routes, address(owner), block.timestamp);
        vm.warp(block.timestamp + 1801);
        vm.roll(block.number + 1);
        address fees = pair.fees();
        assertEq(USDC.balanceOf(fees), 100);
        uint256 b = USDC.balanceOf(address(owner));
        pair.claimFees();
        assertGt(USDC.balanceOf(address(owner)), b);
    }

    function routerPair1GetAmountsOutAndSwapExactTokensForTokensOwner2() public {
        routerPair1GetAmountsOutAndSwapExactTokensForTokens();

        Router.route[] memory routes = new Router.route[](1);
        routes[0] = Router.route(address(USDC), address(FRAX), true);

        assertEq(router.getAmountsOut(USDC_1, routes)[1], pair.getAmountOut(USDC_1, address(USDC)));

        uint256[] memory expectedOutput = router.getAmountsOut(USDC_1, routes);
        owner2.approve(address(USDC), address(router), USDC_1);
        owner2.swapExactTokensForTokens(payable(address(router)), USDC_1, expectedOutput[1], routes, address(owner2), block.timestamp);
        address fees = pair.fees();
        assertEq(USDC.balanceOf(fees), 101);
        uint256 b = USDC.balanceOf(address(owner));
        owner2.claimFees(address(pair));
        assertEq(USDC.balanceOf(address(owner)), b);
    }

    function routerPair2GetAmountsOutAndSwapExactTokensForTokens() public {
        routerPair1GetAmountsOutAndSwapExactTokensForTokensOwner2();

        Router.route[] memory routes = new Router.route[](1);
        routes[0] = Router.route(address(USDC), address(FRAX), false);

        assertEq(router.getAmountsOut(USDC_1, routes)[1], pair2.getAmountOut(USDC_1, address(USDC)));

        uint256[] memory expectedOutput = router.getAmountsOut(USDC_1, routes);
        USDC.approve(address(router), USDC_1);
        router.swapExactTokensForTokens(USDC_1, expectedOutput[1], routes, address(owner), block.timestamp);
    }

    function routerPair3GetAmountsOutAndSwapExactTokensForTokens() public {
        routerPair2GetAmountsOutAndSwapExactTokensForTokens();

        Router.route[] memory routes = new Router.route[](1);
        routes[0] = Router.route(address(FRAX), address(DAI), true);

        assertEq(router.getAmountsOut(TOKEN_1M, routes)[1], pair3.getAmountOut(TOKEN_1M, address(FRAX)));

        uint256[] memory expectedOutput = router.getAmountsOut(TOKEN_1M, routes);
        FRAX.approve(address(router), TOKEN_1M);
        router.swapExactTokensForTokens(TOKEN_1M, expectedOutput[1], routes, address(owner), block.timestamp);
    }

    function deployVoter() public {
        routerAddLiquidity();

        gaugeFactory = new GaugeFactory();
        bribeFactory = new BribeFactory();
        voter = new Voter(address(escrow), address(factory), address(gaugeFactory), address(bribeFactory));

        escrow.setVoter(address(voter));

        assertEq(voter.length(), 0);
    }

    function deployMinter() public {
        deployVoter();

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
    }

    function deployPairFactoryGauge() public {
        deployMinter();

        VELO.approve(address(gaugeFactory), 15 * TOKEN_100K);
        voter.createGauge(address(pair));
        voter.createGauge(address(pair2));
        voter.createGauge(address(pair3));
        assertFalse(voter.gauges(address(pair)) == address(0));

        staking = new TestStakingRewards(address(pair), address(VELO));

        address gaugeAddress = voter.gauges(address(pair));
        address bribeAddress = voter.internal_bribes(gaugeAddress);
        address xBribeAddress = voter.external_bribes(gaugeAddress);

        address gaugeAddress2 = voter.gauges(address(pair2));
        address bribeAddress2 = voter.internal_bribes(gaugeAddress2);

        address gaugeAddress3 = voter.gauges(address(pair3));
        address bribeAddress3 = voter.internal_bribes(gaugeAddress3);

        gauge = Gauge(gaugeAddress);
        gauge2 = Gauge(gaugeAddress2);
        gauge3 = Gauge(gaugeAddress3);

        bribe = InternalBribe(bribeAddress);
        xbribe = ExternalBribe(xBribeAddress);
        bribe2 = InternalBribe(bribeAddress2);
        bribe3 = InternalBribe(bribeAddress3);

        pair.approve(address(gauge), PAIR_1);
        pair.approve(address(staking), PAIR_1);
        pair2.approve(address(gauge2), PAIR_1);
        pair3.approve(address(gauge3), PAIR_1);
        gauge.deposit(PAIR_1, 0);
        staking.stake(PAIR_1);
        gauge2.deposit(PAIR_1, 0);
        gauge3.deposit(PAIR_1, 0);
        assertEq(gauge.totalSupply(), PAIR_1);
        assertEq(gauge.earned(address(escrow), address(owner)), 0);
    }

    function votingEscrowGaugeManipulate() public {
        deployPairFactoryGauge();

        assertEq(gauge.tokenIds(address(owner)), 0);
        pair.approve(address(gauge), PAIR_1);
        gauge.deposit(PAIR_1, 1);
        assertEq(gauge.tokenIds(address(owner)), 1);
        pair.approve(address(gauge), PAIR_1);
        vm.expectRevert(abi.encodePacked(''));
        gauge.deposit(PAIR_1, 2);
        assertEq(gauge.tokenIds(address(owner)), 1);
        vm.expectRevert(abi.encodePacked(''));
        gauge.withdrawToken(0, 2);
        assertEq(gauge.tokenIds(address(owner)), 1);
        gauge.withdrawToken(0, 1);
        assertEq(gauge.tokenIds(address(owner)), 0);
    }

    function deployPairFactoryGaugeOwner2() public {
        votingEscrowGaugeManipulate();

        owner2.approve(address(pair), address(gauge), PAIR_1);
        owner2.approve(address(pair), address(staking), PAIR_1);
        owner2.deposit(address(gauge), PAIR_1, 0);
        owner2.stakeStake(address(staking), PAIR_1);
        assertEq(gauge.totalSupply(), 3 * PAIR_1);
        assertEq(gauge.earned(address(escrow), address(owner2)), 0);
    }

    function withdrawGaugeStake() public {
        deployPairFactoryGaugeOwner2();

        gauge.withdraw(gauge.balanceOf(address(owner)));
        owner2.withdrawGauge(address(gauge), gauge.balanceOf(address(owner2)));
        staking.withdraw(staking._balances(address(owner)));
        owner2.withdrawStake(address(staking), staking._balances(address(owner2)));
        gauge2.withdraw(gauge2.balanceOf(address(owner)));
        gauge3.withdraw(gauge3.balanceOf(address(owner)));
        assertEq(gauge.totalSupply(), 0);
        assertEq(gauge2.totalSupply(), 0);
        assertEq(gauge3.totalSupply(), 0);
    }

    function addGaugeAndBribeRewards() public {
        withdrawGaugeStake();

        VELO.approve(address(gauge), PAIR_1);
        VELO.approve(address(xbribe), PAIR_1);
        VELO.approve(address(staking), PAIR_1);

        gauge.notifyRewardAmount(address(VELO), PAIR_1);
        xbribe.notifyRewardAmount(address(VELO), PAIR_1);
        staking.notifyRewardAmount(PAIR_1);

        assertEq(gauge.rewardRate(address(VELO)), 1653);
        // no reward rate, all or nothing
        // assertEq(xbribe.rewardRate(address(VELO)), 1653);
        assertEq(staking.rewardRate(), 1653);
    }

    function exitAndGetRewardGaugeStake() public {
        addGaugeAndBribeRewards();

        uint256 supply = pair.balanceOf(address(owner));
        pair.approve(address(gauge), supply);
        gauge.deposit(supply, 1);
        gauge.withdraw(gauge.balanceOf(address(owner)));
        assertEq(gauge.totalSupply(), 0);
        pair.approve(address(gauge), supply);
        gauge.deposit(PAIR_1, 1);
        pair.approve(address(staking), supply);
        staking.stake(PAIR_1);
    }

    function voterReset() public {
        exitAndGetRewardGaugeStake();

        vm.warp(block.timestamp + 1 weeks);

        voter.reset(1);
    }

    function voterPokeSelf() public {
        voterReset();

        voter.poke(1);
    }

    function createLock2() public {
        voterPokeSelf();

        VELO.approve(address(escrow), TOKEN_1);
        escrow.create_lock(TOKEN_1, 4 * 365 * 86400);
        vm.warp(block.timestamp + 1);
        assertGt(escrow.balanceOfNFT(1), 995063075414519385);
        assertEq(VELO.balanceOf(address(escrow)), 4 * TOKEN_1);
    }

    function voteHacking() public {
        createLock2();

        address[] memory pools = new address[](1);
        pools[0] = address(pair);
        uint256[] memory weights = new uint256[](1);
        weights[0] = 5000;
        vm.warp(block.timestamp + 1 weeks);

        voter.vote(1, pools, weights);
        assertEq(voter.usedWeights(1), escrow.balanceOfNFT(1)); // within 1000
        assertEq(bribe.balanceOf(1), uint256(voter.votes(1, address(pair))));
        vm.warp(block.timestamp + 1 weeks);

        voter.reset(1);
        assertLt(voter.usedWeights(1), escrow.balanceOfNFT(1));
        assertEq(voter.usedWeights(1), 0);
        assertEq(bribe.balanceOf(1), uint256(voter.votes(1, address(pair))));
        assertEq(bribe.balanceOf(1), 0);
    }

    function gaugePokeHacking() public {
        voteHacking();
        
        assertEq(voter.usedWeights(1), 0);
        assertEq(voter.votes(1, address(pair)), 0);
        voter.poke(1);
        assertEq(voter.usedWeights(1), 0);
        assertEq(voter.votes(1, address(pair)), 0);
    }

    function gaugeVoteAndBribeBalanceOf() public {
        gaugePokeHacking();
        
        address[] memory pools = new address[](2);
        pools[0] = address(pair);
        pools[1] = address(pair2);
        uint256[] memory weights = new uint256[](2);
        weights[0] = 5000;
        weights[1] = 5000;
        vm.warp(block.timestamp + 1 weeks);

        voter.vote(1, pools, weights);
        weights[0] = 50000;
        weights[1] = 50000;

        voter.vote(4, pools, weights);
        console2.log(voter.usedWeights(1));
        console2.log(voter.usedWeights(4));
        assertFalse(voter.totalWeight() == 0);
        assertFalse(bribe.balanceOf(1) == 0);
    }

    function gaugePokeHacking2() public {
        gaugeVoteAndBribeBalanceOf();

        uint256 weightBefore = voter.usedWeights(1);
        uint256 votesBefore = voter.votes(1, address(pair));
        voter.poke(1);
        assertEq(voter.usedWeights(1), weightBefore);
        assertEq(voter.votes(1, address(pair)), votesBefore);
    }

    function voteHackingBreakMint() public {
        gaugePokeHacking2();

        address[] memory pools = new address[](2);
        pools[0] = address(pair);
        uint256[] memory weights = new uint256[](2);
        weights[0] = 5000;
        vm.warp(block.timestamp + 1 weeks);

        voter.vote(1, pools, weights);

        assertEq(voter.usedWeights(1), escrow.balanceOfNFT(1)); // within 1000
        assertEq(bribe.balanceOf(1), uint256(voter.votes(1, address(pair))));
    }

    function gaugePokeHacking3() public {
        voteHackingBreakMint();

        assertEq(voter.usedWeights(1), uint256(voter.votes(1, address(pair))));
        voter.poke(1);
        assertEq(voter.usedWeights(1), uint256(voter.votes(1, address(pair))));
    }

    function gaugeDistributeBasedOnVoting() public {
        gaugePokeHacking3();

        VELO.approve(address(voter), PAIR_1);
        voter.notifyRewardAmount(PAIR_1);
        voter.updateAll();
        voter.distro();
    }

    function bribeClaimRewards() public {
        gaugeDistributeBasedOnVoting();

        address[] memory rewards = new address[](1);
        rewards[0] = address(VELO);
        bribe.getReward(1, rewards);
        vm.warp(block.timestamp + 691200);
        vm.roll(block.number + 1);
        bribe.getReward(1, rewards);
    }

    function routerPair1GetAmountsOutAndSwapExactTokensForTokens2() public {
        bribeClaimRewards();

        Router.route[] memory routes = new Router.route[](1);
        routes[0] = Router.route(address(USDC), address(FRAX), true);

        uint256[] memory expectedOutput = router.getAmountsOut(USDC_1, routes);
        USDC.approve(address(router), USDC_1);
        router.swapExactTokensForTokens(USDC_1, expectedOutput[1], routes, address(owner), block.timestamp);
    }

    function routerPair2GetAmountsOutAndSwapExactTokensForTokens2() public {
        routerPair1GetAmountsOutAndSwapExactTokensForTokens2();

        Router.route[] memory routes = new Router.route[](1);
        routes[0] = Router.route(address(USDC), address(FRAX), false);

        uint256[] memory expectedOutput = router.getAmountsOut(USDC_1, routes);
        USDC.approve(address(router), USDC_1);
        router.swapExactTokensForTokens(USDC_1, expectedOutput[1], routes, address(owner), block.timestamp);
    }

    function routerPair1GetAmountsOutAndSwapExactTokensForTokens2Again() public {
        routerPair2GetAmountsOutAndSwapExactTokensForTokens2();

        Router.route[] memory routes = new Router.route[](1);
        routes[0] = Router.route(address(FRAX), address(USDC), false);

        uint256[] memory expectedOutput = router.getAmountsOut(TOKEN_1, routes);
        FRAX.approve(address(router), TOKEN_1);
        router.swapExactTokensForTokens(TOKEN_1, expectedOutput[1], routes, address(owner), block.timestamp);
    }

    function routerPair2GetAmountsOutAndSwapExactTokensForTokens2Again() public {
        routerPair1GetAmountsOutAndSwapExactTokensForTokens2Again();

        Router.route[] memory routes = new Router.route[](1);
        routes[0] = Router.route(address(FRAX), address(USDC), false);

        uint256[] memory expectedOutput = router.getAmountsOut(TOKEN_1, routes);
        FRAX.approve(address(router), TOKEN_1);
        router.swapExactTokensForTokens(TOKEN_1, expectedOutput[1], routes, address(owner), block.timestamp);
    }

    function routerPair1Pair2GetAmountsOutAndSwapExactTokensForTokens() public {
        routerPair2GetAmountsOutAndSwapExactTokensForTokens2Again();

        Router.route[] memory route = new Router.route[](2);
        route[0] = Router.route(address(FRAX), address(USDC), false);
        route[1] = Router.route(address(USDC), address(FRAX), true);

        uint256 before = FRAX.balanceOf(address(owner)) - TOKEN_1;

        uint256[] memory expectedOutput = router.getAmountsOut(TOKEN_1, route);
        FRAX.approve(address(router), TOKEN_1);
        router.swapExactTokensForTokens(TOKEN_1, expectedOutput[2], route, address(owner), block.timestamp);
        uint256 after_ = FRAX.balanceOf(address(owner));
        assertEq(after_ - before, expectedOutput[2]);
    }

    function distributeAndClaimFees() public {
        routerPair1Pair2GetAmountsOutAndSwapExactTokensForTokens();

        vm.warp(block.timestamp + 691200);
        vm.roll(block.number + 1);
        address[] memory rewards = new address[](2);
        rewards[0] = address(FRAX);
        rewards[1] = address(USDC);
        bribe.getReward(1, rewards);

        address[] memory gauges = new address[](1);
        gauges[0] = address(gauge);
        voter.distributeFees(gauges);
    }

    function minterMint() public {
        distributeAndClaimFees();

        console2.log(distributor.last_token_time());
        console2.log(distributor.timestamp());
        address[] memory claimants = new address[](1);
        claimants[0] = address(owner);
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = TOKEN_1;
        minter.initialize(claimants, amounts, TOKEN_1);
        minter.update_period();
        voter.updateGauge(address(gauge));
        console2.log(VELO.balanceOf(address(distributor)));
        console2.log(distributor.claimable(1));
        uint256 claimable = voter.claimable(address(gauge));
        VELO.approve(address(staking), claimable);
        staking.notifyRewardAmount(claimable);
        voter.distro();
        vm.warp(block.timestamp + 1800);
        vm.roll(block.number + 1);
    }

    function gaugeClaimRewards() public {
        minterMint();

        assertEq(address(owner), escrow.ownerOf(1));
        assertTrue(escrow.isApprovedOrOwner(address(owner), 1));
        gauge.withdraw(gauge.balanceOf(address(owner)));
        staking.withdraw(staking._balances(address(owner)));
        vm.warp(block.timestamp + 1);
        pair.approve(address(gauge), PAIR_1);
        vm.warp(block.timestamp + 1);
        gauge.deposit(PAIR_1, 0);
        staking.getReward();
        vm.warp(block.timestamp + 1);
        uint256 before = VELO.balanceOf(address(owner));
        vm.warp(block.timestamp + 1);
        gauge.batchRewardPerToken(address(VELO), 200);
        vm.warp(block.timestamp + 1);
        gauge.batchRewardPerToken(address(VELO), 200);
        vm.warp(block.timestamp + 1);
        gauge.batchRewardPerToken(address(VELO), 200);
        vm.warp(block.timestamp + 1);
        gauge.batchRewardPerToken(address(VELO), 200);
        vm.warp(block.timestamp + 1);
        gauge.batchRewardPerToken(address(VELO), 200);
        vm.warp(block.timestamp + 1);
        uint256 earned = gauge.earned(address(VELO), address(owner));
        address[] memory rewards = new address[](1);
        rewards[0] = address(VELO);
        vm.warp(block.timestamp + 1);
        gauge.getReward(address(owner), rewards);
        vm.warp(block.timestamp + 1);
        uint256 after_ = VELO.balanceOf(address(owner));
        uint256 received = after_ - before;

        gauge.withdraw(gauge.balanceOf(address(owner)));
        pair.approve(address(gauge), PAIR_1);
        gauge.deposit(PAIR_1, 1);
        gauge.getReward(address(owner), rewards);
        gauge.withdraw(gauge.balanceOf(address(owner)));
        pair.approve(address(gauge), PAIR_1);
        gauge.deposit(PAIR_1, 0);
        gauge.getReward(address(owner), rewards);
        gauge.withdraw(gauge.balanceOf(address(owner)));
        pair.approve(address(gauge), PAIR_1);
        gauge.deposit(PAIR_1, 1);
        gauge.getReward(address(owner), rewards);
        gauge.withdraw(gauge.balanceOf(address(owner)));
        pair.approve(address(gauge), PAIR_1);
        gauge.deposit(PAIR_1, 0);
        gauge.getReward(address(owner), rewards);
        gauge.withdraw(gauge.balanceOf(address(owner)));
        pair.approve(address(gauge), PAIR_1);
        gauge.deposit(PAIR_1, 1);
        gauge.getReward(address(owner), rewards);
        gauge.withdraw(gauge.balanceOf(address(owner)));
        pair.approve(address(gauge), PAIR_1);
        gauge.deposit(PAIR_1, 0);
        gauge.getReward(address(owner), rewards);
        vm.warp(block.timestamp + 604800);
        vm.roll(block.number + 1);
        gauge.getReward(address(owner), rewards);
        gauge.withdraw(gauge.balanceOf(address(owner)));
    }

    function gaugeClaimRewardsAfterExpiry() public {
        gaugeClaimRewards();

        address[] memory rewards = new address[](1);
        rewards[0] = address(VELO);
        pair.approve(address(gauge), PAIR_1);
        gauge.deposit(PAIR_1, 1);
        gauge.getReward(address(owner), rewards);
        gauge.withdraw(gauge.balanceOf(address(owner)));
        pair.approve(address(gauge), PAIR_1);
        gauge.deposit(PAIR_1, 1);
        gauge.getReward(address(owner), rewards);
        gauge.withdraw(gauge.balanceOf(address(owner)));
        pair.approve(address(gauge), PAIR_1);
        gauge.deposit(PAIR_1, 1);
        gauge.getReward(address(owner), rewards);
        gauge.withdraw(gauge.balanceOf(address(owner)));
        pair.approve(address(gauge), PAIR_1);
        gauge.deposit(PAIR_1, 1);
        gauge.getReward(address(owner), rewards);
        gauge.withdraw(gauge.balanceOf(address(owner)));
        pair.approve(address(gauge), PAIR_1);
        gauge.deposit(PAIR_1, 1);
        gauge.getReward(address(owner), rewards);
        gauge.withdraw(gauge.balanceOf(address(owner)));
        pair.approve(address(gauge), PAIR_1);
        gauge.deposit(PAIR_1, 1);
        gauge.getReward(address(owner), rewards);
        gauge.withdraw(gauge.balanceOf(address(owner)));
        pair.approve(address(gauge), PAIR_1);
        gauge.deposit(PAIR_1, 1);
        gauge.getReward(address(owner), rewards);
        vm.warp(block.timestamp + 604800);
        vm.roll(block.number + 1);
        gauge.getReward(address(owner), rewards);
        gauge.withdraw(gauge.balanceOf(address(owner)));
    }

    function votingEscrowDecay() public {
        gaugeClaimRewardsAfterExpiry();

        address[] memory bribes_ = new address[](1);
        bribes_[0] = address(bribe);
        address[][] memory rewards = new address[][](1);
        address[] memory reward = new address[](1);
        reward[0] = address(DAI);
        rewards[0] = reward;
        voter.claimBribes(bribes_, rewards, 1);
        voter.claimFees(bribes_, rewards, 1);
        uint256 supply = escrow.totalSupply();
        assertGt(supply, 0);
        vm.warp(block.timestamp + 4*365*86400);
        vm.roll(block.number + 1);
        assertEq(escrow.balanceOfNFT(1), 0);
        assertEq(escrow.totalSupply(), 0);
        vm.warp(block.timestamp + 1 weeks);

        voter.reset(1);
        escrow.withdraw(1);
    }

    function routerAddLiquidityOwner3() public {
        votingEscrowDecay();

        owner3.approve(address(USDC), address(router), 1e12);
        owner3.approve(address(FRAX), address(router), TOKEN_1M);
        owner3.addLiquidity(payable(address(router)), address(FRAX), address(USDC), true, TOKEN_1M, 1e12, 0, 0, address(owner3), block.timestamp);
    }

    function deployPairFactoryGaugeOwner3() public {
        routerAddLiquidityOwner3();

        owner3.approve(address(pair), address(gauge), PAIR_1);
        owner3.deposit(address(gauge), PAIR_1, 0);
    }

    function gaugeClaimRewardsOwner3() public {
        deployPairFactoryGaugeOwner3();

        owner3.withdrawGauge(address(gauge), gauge.balanceOf(address(owner3)));
        owner3.approve(address(pair), address(gauge), PAIR_1);
        owner3.deposit(address(gauge), PAIR_1, 0);
        owner3.withdrawGauge(address(gauge), gauge.balanceOf(address(owner3)));
        gauge.batchRewardPerToken(address(VELO), 200);
        owner3.approve(address(pair), address(gauge), PAIR_1);
        owner3.deposit(address(gauge), PAIR_1, 0);
        gauge.batchRewardPerToken(address(VELO), 200);
        gauge.batchRewardPerToken(address(VELO), 200);
        gauge.batchRewardPerToken(address(VELO), 200);
        gauge.batchRewardPerToken(address(VELO), 200);

        address[] memory rewards = new address[](1);
        rewards[0] = address(VELO);
        owner3.getGaugeReward(address(gauge), address(owner3), rewards);
        owner3.withdrawGauge(address(gauge), gauge.balanceOf(address(owner3)));
        owner3.approve(address(pair), address(gauge), PAIR_1);
        owner3.deposit(address(gauge), PAIR_1, 0);
        owner3.getGaugeReward(address(gauge), address(owner3), rewards);
        owner3.withdrawGauge(address(gauge), gauge.balanceOf(address(owner3)));
        owner3.approve(address(pair), address(gauge), PAIR_1);
        owner3.deposit(address(gauge), PAIR_1, 0);
        owner3.getGaugeReward(address(gauge), address(owner3), rewards);
        owner3.getGaugeReward(address(gauge), address(owner3), rewards);
        owner3.getGaugeReward(address(gauge), address(owner3), rewards);
        owner3.getGaugeReward(address(gauge), address(owner3), rewards);

        owner3.withdrawGauge(address(gauge), gauge.balanceOf(address(owner)));
        owner3.approve(address(pair), address(gauge), PAIR_1);
        owner3.deposit(address(gauge), PAIR_1, 0);
        owner3.getGaugeReward(address(gauge), address(owner3), rewards);
    }

    function minterMint2() public {
        gaugeClaimRewardsOwner3();

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
        voter.distro();
        address[][] memory tokens = new address[][](1);
        address[] memory token = new address[](1);
        token[0] = address(VELO);
        tokens[0] = token;
        voter.claimRewards(gauges, tokens);
        assertEq(gauge.rewardRate(address(VELO)), staking.rewardRate());
        console2.log(gauge.rewardPerTokenStored(address(VELO)));
    }

    function gaugeClaimRewardsOwner3NextCycle() public {
        minterMint2();

        owner3.withdrawGauge(address(gauge), gauge.balanceOf(address(owner3)));
        console2.log(gauge.rewardPerTokenStored(address(VELO)));
        owner3.approve(address(pair), address(gauge), PAIR_1);
        owner3.deposit(address(gauge), PAIR_1, 0);
        uint256 before = VELO.balanceOf(address(owner3));
        vm.warp(block.timestamp + 1);
        // uint256 earned = gauge.earned(address(VELO), address(owner3));
        address[] memory rewards = new address[](1);
        rewards[0] = address(VELO);
        owner3.getGaugeReward(address(gauge), address(owner3), rewards);
        uint256 after_ = VELO.balanceOf(address(owner3));
        uint256 received = after_ - before;
        assertGt(received, 0);
        console2.log(gauge.rewardPerTokenStored(address(VELO)));

        owner3.withdrawGauge(address(gauge), gauge.balanceOf(address(owner)));
        owner3.approve(address(pair), address(gauge), PAIR_1);
        owner3.deposit(address(gauge), PAIR_1, 0);
        owner3.getGaugeReward(address(gauge), address(owner3), rewards);
    }

    function gaugeClaimRewards2() public {
        gaugeClaimRewardsOwner3NextCycle();

        pair.approve(address(gauge), PAIR_1);
        gauge.deposit(PAIR_1, 0);
        LR.approve(address(gauge), LR.balanceOf(address(owner)));
        gauge.notifyRewardAmount(address(LR), LR.balanceOf(address(owner)));

        vm.warp(block.timestamp + 604800);
        vm.roll(block.number + 1);
        uint256 reward1 = gauge.earned(address(LR), address(owner));
        uint256 reward3 = gauge.earned(address(LR), address(owner3));
        assertLt(2e25 - (reward1 + reward3), 1e5);
        address[] memory rewards = new address[](1);
        rewards[0] = address(LR);
        gauge.getReward(address(owner), rewards);
        owner2.getGaugeReward(address(gauge), address(owner2), rewards);
        owner3.getGaugeReward(address(gauge), address(owner3), rewards);
        gauge.withdraw(gauge.balanceOf(address(owner)));
    }

    function testGaugeClaimRewards3() public {
        gaugeClaimRewards2();

        pair.approve(address(gauge), PAIR_1);
        gauge.deposit(PAIR_1, 0);
        VELO.approve(address(gauge), VELO.balanceOf(address(owner)));
        gauge.notifyRewardAmount(address(VELO), VELO.balanceOf(address(owner)));

        vm.warp(block.timestamp + 604800);
        vm.roll(block.number + 1);
        address[] memory rewards = new address[](1);
        rewards[0] = address(LR);
        gauge.getReward(address(owner), rewards);
        gauge.withdraw(gauge.balanceOf(address(owner)));
    }
}
