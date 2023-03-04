// 1:1 with Hardhat test
pragma solidity 0.8.13;

import './BaseTest.sol';

contract WashTradeTest is BaseTest {
    VotingEscrow escrow;
    GaugeFactory gaugeFactory;
    BribeFactory bribeFactory;
    WrappedExternalBribeFactory wxbribeFactory;
    Voter voter;
    Gauge gauge3;

    function deployBaseCoins() public {
        vm.warp(block.timestamp + 1 weeks); // put some initial time in

        deployOwners();
        deployCoins();
        mintStables();
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1e25;
        mintFlow(owners, amounts);

        VeArtProxy artProxy = new VeArtProxy();
        escrow = new VotingEscrow(address(FLOW), address(artProxy), owners[0]);
    }

    function createLock() public {
        deployBaseCoins();

        FLOW.approve(address(escrow), TOKEN_1);
        escrow.create_lock(TOKEN_1, FOUR_YEARS);
        vm.roll(block.number + 1); // fwd 1 block because escrow.balanceOfNFT() returns 0 in same block
        assertGt(escrow.balanceOfNFT(1), 995063075414519385);
        assertEq(FLOW.balanceOf(address(escrow)), TOKEN_1);
    }

    function votingEscrowMerge() public {
        createLock();

        FLOW.approve(address(escrow), TOKEN_1);
        escrow.create_lock(TOKEN_1, FOUR_YEARS);
        vm.roll(block.number + 1);
        assertGt(escrow.balanceOfNFT(2), 995063075414519385);
        assertEq(FLOW.balanceOf(address(escrow)), 2 * TOKEN_1);
        escrow.merge(2, 1);
        assertGt(escrow.balanceOfNFT(1), 1990039602248405587);
        assertEq(escrow.balanceOfNFT(2), 0);
    }

    function confirmTokensForFraxUsdc() public {
        votingEscrowMerge();
        deployPairFactoryAndRouter();
        deployPairWithOwner(address(owner));

        (address token0, address token1) = router.sortTokens(address(USDC), address(FRAX));
        assertEq(pair.token0(), token0);
        assertEq(pair.token1(), token1);
    }

    function mintAndBurnTokensForPairFraxUsdc() public {
        confirmTokensForFraxUsdc();

        USDC.transfer(address(pair), USDC_1);
        FRAX.transfer(address(pair), TOKEN_1);
        pair.mint(address(owner));
        assertEq(pair.getAmountOut(USDC_1, address(USDC)), 945128557522723966);
    }

    function routerAddLiquidity() public {
        mintAndBurnTokensForPairFraxUsdc();

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

    function deployVoter() public {
        gaugeFactory = new GaugeFactory();
        bribeFactory = new BribeFactory();
        wxbribeFactory = new WrappedExternalBribeFactory();
        voter = new Voter(address(escrow), address(factory), address(gaugeFactory), address(bribeFactory), address(wxbribeFactory));
        wxbribeFactory.setVoter(address(voter));
        factory.setVoter(address(voter));

        address[] memory tokens = new address[](4);
        tokens[0] = address(USDC);
        tokens[1] = address(FRAX);
        tokens[2] = address(DAI);
        tokens[3] = address(FLOW);
        voter.initialize(tokens, address(owner));

        assertEq(voter.length(), 0);
    }

    function deployPairFactoryGauge() public {
        routerAddLiquidity();

        FLOW.approve(address(gaugeFactory), 5 * TOKEN_100K);
        voter.createGauge(address(pair3));
        assertFalse(voter.gauges(address(pair3)) == address(0));

        address gaugeAddr3 = voter.gauges(address(pair3));

        gauge3 = Gauge(gaugeAddr3);

        uint256 total = pair3.balanceOf(address(owner));
        pair3.approve(address(gauge3), total);
        gauge3.deposit(total, 0);
        assertEq(gauge3.totalSupply(), total);
        assertEq(gauge3.earned(address(escrow), address(owner)), 0);
    }

    function routerPair3GetAmountsOutAndSwapExactTokensForTokens() public {
        deployPairFactoryGauge();

        Router.route[] memory routes = new Router.route[](1);
        routes[0] = Router.route(address(FRAX), address(DAI), true);
        Router.route[] memory routes2 = new Router.route[](1);
        routes2[0] = Router.route(address(DAI), address(FRAX), true);

        uint256 i;
        for (i = 0; i < 10; i++) {
            assertEq(router.getAmountsOut(TOKEN_1M, routes)[1], pair3.getAmountOut(TOKEN_1M, address(FRAX)));

            uint256[] memory expectedOutput = router.getAmountsOut(TOKEN_1M, routes);
            FRAX.approve(address(router), TOKEN_1M);
            router.swapExactTokensForTokens(TOKEN_1M, expectedOutput[1], routes, address(owner), block.timestamp);

            assertEq(router.getAmountsOut(TOKEN_1M, routes2)[1], pair3.getAmountOut(TOKEN_1M, address(DAI)));

            uint256[] memory expectedOutput2 = router.getAmountsOut(TOKEN_1M, routes2);
            DAI.approve(address(router), TOKEN_1M);
            router.swapExactTokensForTokens(TOKEN_1M, expectedOutput2[1], routes2, address(owner), block.timestamp);
        }
    }

    function voterReset() public {
        routerPair3GetAmountsOutAndSwapExactTokensForTokens();

        escrow.setVoter(address(voter));
        voter.reset(1);
    }

    function voterPokeSelf() public {
        voterReset();

        voter.poke(1);
    }

    function voterVoteAndBribeBalanceOf() public {
        voterPokeSelf();

        vm.warp(block.timestamp + 1 weeks);

        address[] memory pairs = new address[](2);
        pairs[0] = address(pair3);
        pairs[1] = address(pair2);
        uint256[] memory weights = new uint256[](2);
        weights[0] = 5000;
        weights[1] = 5000;
        voter.vote(1, pairs, weights);
        assertFalse(voter.totalWeight() == 0);
    }
}
