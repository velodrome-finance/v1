// 1:1 with Hardhat test
pragma solidity 0.8.13;

import './BaseTest.sol';

contract MinterTest is BaseTest {
    VotingEscrow escrow;
    GaugeFactory gaugeFactory;
    BribeFactory bribeFactory;
    WrappedExternalBribeFactory wxbribeFactory;
    Voter voter;
    RewardsDistributor distributor;
    Minter minter;

    function deployBase() public {
        vm.warp(block.timestamp + 1 weeks); // put some initial time in

        deployOwners();
        deployCoins();
        mintStables();
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1e25;
        mintFlow(owners, amounts);

        VeArtProxy artProxy = new VeArtProxy();
        escrow = new VotingEscrow(address(FLOW), address(artProxy), owners[0]);
        factory = new PairFactory();
        router = new Router(address(factory), address(owner));
        gaugeFactory = new GaugeFactory();
        bribeFactory = new BribeFactory();
        wxbribeFactory = new WrappedExternalBribeFactory();
        voter = new Voter(address(escrow), address(factory), address(gaugeFactory), address(bribeFactory), address(wxbribeFactory));

        wxbribeFactory.setVoter(address(voter));
        factory.setVoter(address(voter));

        address[] memory tokens = new address[](2);
        tokens[0] = address(FRAX);
        tokens[1] = address(FLOW);
        voter.initialize(tokens, address(owner));
        FLOW.approve(address(escrow), TOKEN_1);
        escrow.create_lock(TOKEN_1, FOUR_YEARS);
        distributor = new RewardsDistributor(address(escrow));
        escrow.setVoter(address(voter));

        minter = new Minter(address(voter), address(escrow), address(distributor));
        distributor.setDepositor(address(minter));
        FLOW.setMinter(address(minter));

        FLOW.approve(address(router), TOKEN_1);
        FRAX.approve(address(router), TOKEN_1);
        router.addLiquidity(address(FRAX), address(FLOW), false, TOKEN_1, TOKEN_1, 0, 0, address(owner), block.timestamp);

        address pair = router.pairFor(address(FRAX), address(FLOW), false);

        FLOW.approve(address(voter), 5 * TOKEN_100K);
        voter.createGauge(pair);
        vm.roll(block.number + 1); // fwd 1 block because escrow.balanceOfNFT() returns 0 in same block
        assertGt(escrow.balanceOfNFT(1), 995063075414519385);
        assertEq(FLOW.balanceOf(address(escrow)), TOKEN_1);

        address[] memory pools = new address[](1);
        pools[0] = pair;
        uint256[] memory weights = new uint256[](1);
        weights[0] = 5000;
        voter.vote(1, pools, weights);
    }

    function initializeVotingEscrow() public {
        deployBase();

        Minter.Claim[] memory claims = new Minter.Claim[](1);
        claims[0] = Minter.Claim({
            claimant: address(owner),
            amount: TOKEN_1M,
            lockTime: 86400 * 7 * 52 * 4
        });
        minter.initialMintAndLock(claims, 2e25);
        minter.startActivePeriod();

        assertEq(escrow.ownerOf(2), address(owner));
        assertEq(escrow.ownerOf(3), address(0));
        vm.roll(block.number + 1);
        assertEq(FLOW.balanceOf(address(minter)), 19 * TOKEN_1M);
    }

    function testMinterWeeklyDistribute() public {
        initializeVotingEscrow();

        minter.update_period();
        assertEq(minter.weekly(), 15 * TOKEN_1M); // 15M

        _elapseOneWeek();

        minter.update_period();
        assertEq(distributor.claimable(1), 0);
        assertLt(minter.weekly(), 15 * TOKEN_1M); // <15M for week shift

        _elapseOneWeek();

        minter.update_period();
        uint256 claimable = distributor.claimable(1);
        /**
         * This has been updated from 128115516517529 to
         * 197073360700 because originally in VELO the
         * constructor mints 0 tokens, but now we are minting
         * an initial supply instead of using the initialMint
         * function.
         */

        assertGt(claimable, 197073360700);

        distributor.claim(1);
        assertEq(distributor.claimable(1), 0);

        uint256 weekly = minter.weekly();

        console2.log(weekly);
        console2.log(minter.calculate_growth(weekly));
        console2.log(FLOW.totalSupply());
        console2.log(escrow.totalSupply());

        _elapseOneWeek();

        minter.update_period();
        console2.log(distributor.claimable(1));
        distributor.claim(1);

        _elapseOneWeek();

        minter.update_period();
        console2.log(distributor.claimable(1));
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 1;
        distributor.claim_many(tokenIds);

        _elapseOneWeek();

        minter.update_period();
        console2.log(distributor.claimable(1));
        distributor.claim(1);

        _elapseOneWeek();

        minter.update_period();
        console2.log(distributor.claimable(1));
        distributor.claim_many(tokenIds);

        _elapseOneWeek();

        minter.update_period();
        console2.log(distributor.claimable(1));
        distributor.claim(1);
    }

    function _elapseOneWeek() private {
        vm.warp(block.timestamp + ONE_WEEK);
        vm.roll(block.number + 1);
    }
}
