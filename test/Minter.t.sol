// 1:1 with Hardhat test
pragma solidity 0.8.13;

import './BaseTest.sol';

contract MinterTest is BaseTest {
    VotingEscrow escrow;
    GaugeFactory gaugeFactory;
    BribeFactory bribeFactory;
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
        mintVelo(owners, amounts);

        VeArtProxy artProxy = new VeArtProxy();
        escrow = new VotingEscrow(address(VELO), address(artProxy));
        factory = new PairFactory();
        router = new Router(address(factory), address(owner));
        gaugeFactory = new GaugeFactory();
        bribeFactory = new BribeFactory();
        voter = new Voter(address(escrow), address(factory), address(gaugeFactory), address(bribeFactory));

        address[] memory tokens = new address[](2);
        tokens[0] = address(FRAX);
        tokens[1] = address(VELO);
        voter.initialize(tokens, address(owner));
        VELO.approve(address(escrow), TOKEN_1);
        escrow.create_lock(TOKEN_1, 4 * 365 * 86400);
        distributor = new RewardsDistributor(address(escrow));
        escrow.setVoter(address(voter));

        minter = new Minter(address(voter), address(escrow), address(distributor));
        distributor.setDepositor(address(minter));
        VELO.setMinter(address(minter));

        VELO.approve(address(router), TOKEN_1);
        FRAX.approve(address(router), TOKEN_1);
        router.addLiquidity(address(FRAX), address(VELO), false, TOKEN_1, TOKEN_1, 0, 0, address(owner), block.timestamp);

        address pair = router.pairFor(address(FRAX), address(VELO), false);

        VELO.approve(address(voter), 5 * TOKEN_100K);
        voter.createGauge(pair);
        vm.roll(block.number + 1); // fwd 1 block because escrow.balanceOfNFT() returns 0 in same block
        assertGt(escrow.balanceOfNFT(1), 995063075414519385);
        assertEq(VELO.balanceOf(address(escrow)), TOKEN_1);

        address[] memory pools = new address[](1);
        pools[0] = pair;
        uint256[] memory weights = new uint256[](1);
        weights[0] = 5000;
        voter.vote(1, pools, weights);
    }

    function initializeVotingEscrow() public {
        deployBase();

        address[] memory claimants = new address[](1);
        claimants[0] = address(owner);
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = TOKEN_1M;
        minter.initialize(claimants, amounts, 2e25);
        assertEq(escrow.ownerOf(2), address(owner));
        assertEq(escrow.ownerOf(3), address(0));
        vm.roll(block.number + 1);
        assertEq(VELO.balanceOf(address(minter)), 19 * TOKEN_1M);
    }

    function testMinterWeeklyDistribute() public {
        initializeVotingEscrow();

        minter.update_period();
        assertEq(minter.weekly(), 15 * TOKEN_1M); // 15M
        vm.warp(block.timestamp + 86400 * 7);
        vm.roll(block.number + 1);
        minter.update_period();
        assertEq(distributor.claimable(1), 0);
        assertLt(minter.weekly(), 15 * TOKEN_1M); // <15M for week shift
        vm.warp(block.timestamp + 86400 * 7);
        vm.roll(block.number + 1);
        minter.update_period();
        uint256 claimable = distributor.claimable(1);
        assertGt(claimable, 128115516517529);
        distributor.claim(1);
        assertEq(distributor.claimable(1), 0);

        uint256 weekly = minter.weekly();
        console2.log(weekly);
        console2.log(minter.calculate_growth(weekly));
        console2.log(VELO.totalSupply());
        console2.log(escrow.totalSupply());

        vm.warp(block.timestamp + 86400 * 7);
        vm.roll(block.number + 1);
        minter.update_period();
        console2.log(distributor.claimable(1));
        distributor.claim(1);
        vm.warp(block.timestamp + 86400 * 7);
        vm.roll(block.number + 1);
        minter.update_period();
        console2.log(distributor.claimable(1));
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 1;
        distributor.claim_many(tokenIds);
        vm.warp(block.timestamp + 86400 * 7);
        vm.roll(block.number + 1);
        minter.update_period();
        console2.log(distributor.claimable(1));
        distributor.claim(1);
        vm.warp(block.timestamp + 86400 * 7);
        vm.roll(block.number + 1);
        minter.update_period();
        console2.log(distributor.claimable(1));
        distributor.claim_many(tokenIds);
        vm.warp(block.timestamp + 86400 * 7);
        vm.roll(block.number + 1);
        minter.update_period();
        console2.log(distributor.claimable(1));
        distributor.claim(1);
    }
}
