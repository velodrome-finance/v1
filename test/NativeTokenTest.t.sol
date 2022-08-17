pragma solidity 0.8.13;

import './BaseTest.sol';

contract NativeTokenTest is BaseTest {

    Pair _pair;

    function deploySinglePairWithOwner(address _owner) public {
        TestOwner(_owner).approve(address(WETH), address(router), TOKEN_1);
        TestOwner(_owner).approve(address(USDC), address(router), USDC_1);
        TestOwner(_owner).addLiquidity(payable(address(router)), address(WETH), address(USDC), false, TOKEN_1, USDC_1, 0, 0, address(owner), block.timestamp);
    }

    function deployPair() public {
        deployOwners();
        deployCoins();
        mintStables();
        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 2e25;
        amounts[1] = 1e25;
        amounts[2] = 1e25;
        mintWETH(owners, amounts);
        dealETH(owners, amounts);

        deployPairFactoryAndRouter();
        deploySinglePairWithOwner(address(owner));
        deploySinglePairWithOwner(address(owner2));

        _pair = Pair(factory.getPair(address(USDC), address(WETH), false));
    }

    function routerAddLiquidityETH() public {
        deployPair();

        // add initial liquidity from owner
        USDC.approve(address(router), USDC_100K);
        WETH.approve(address(router), TOKEN_100K);
        router.addLiquidityETH{value: TOKEN_100K}(address(USDC), false, USDC_100K, USDC_100K, TOKEN_100K, address(owner), block.timestamp);
    }

    function routerAddLiquidityETHOwner2() public {
        routerAddLiquidityETH();

        owner2.approve(address(USDC), address(router), USDC_100K);
        owner2.approve(address(WETH), address(router), TOKEN_100K);
        owner2.addLiquidityETH{value: TOKEN_100K}(payable(address(router)), address(USDC), false, USDC_100K, USDC_100K, TOKEN_100K, address(owner), block.timestamp);
    }

    function testRemoveETHLiquidity() public {
        routerAddLiquidityETHOwner2();

        uint256 initial_eth = address(this).balance;
        uint256 initial_usdc = USDC.balanceOf(address(this));
        uint256 pair_initial_eth = address(_pair).balance;
        uint256 pair_initial_usdc = USDC.balanceOf(address(_pair));

        // add liquidity to pool
        USDC.approve(address(router), USDC_100K);
        WETH.approve(address(router), TOKEN_100K);
        (,, uint256 liquidity) = router.addLiquidityETH{value: TOKEN_100K}(address(USDC), false, USDC_100K, USDC_100K, TOKEN_100K, address(owner), block.timestamp);

        assertEq(address(this).balance, initial_eth - TOKEN_100K);
        assertEq(USDC.balanceOf(address(this)), initial_usdc - USDC_100K);

        (uint256 amountUSDC, uint256 amountETH) = router.quoteRemoveLiquidity(address(USDC), address(WETH), false, liquidity);
        // approve transfer of lp tokens
        Pair(_pair).approve(address(router), liquidity);
        router.removeLiquidityETH(address(USDC), false, liquidity, amountUSDC, amountETH, address(owner), block.timestamp);

        assertEq(address(this).balance, initial_eth);
        assertEq(USDC.balanceOf(address(this)), initial_usdc);
        assertEq(address(_pair).balance, pair_initial_eth);
        assertEq(USDC.balanceOf(address(_pair)), pair_initial_usdc);
    }

    function testRouterPairGetAmountsOutAndSwapExactTokensForETH() public {
        routerAddLiquidityETHOwner2();

        Router.route[] memory routes = new Router.route[](1);
        routes[0] = Router.route(address(USDC), address(WETH), false);

        assertEq(router.getAmountsOut(USDC_1, routes)[1], _pair.getAmountOut(USDC_1, address(USDC)));

        uint256[] memory expectedOutput = router.getAmountsOut(USDC_1, routes);
        USDC.approve(address(router), USDC_1);
        router.swapExactTokensForETH(USDC_1, expectedOutput[1], routes, address(owner), block.timestamp);
    }

    function testRouterPairGetAmountsOutAndSwapExactETHForTokens() public {
        routerAddLiquidityETHOwner2();

        Router.route[] memory routes = new Router.route[](1);
        routes[0] = Router.route(address(WETH), address(USDC), false);

        assertEq(router.getAmountsOut(TOKEN_1, routes)[1], _pair.getAmountOut(TOKEN_1, address(WETH)));

        uint256[] memory expectedOutput = router.getAmountsOut(TOKEN_1, routes);
        USDC.approve(address(router), TOKEN_1);
        router.swapExactETHForTokens{value: TOKEN_1}(expectedOutput[1], routes, address(owner), block.timestamp);
    }
}
