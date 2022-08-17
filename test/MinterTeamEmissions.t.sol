// 1:1 with Hardhat test
pragma solidity 0.8.13;

import "./BaseTest.sol";

contract MinterTeamEmissions is BaseTest {
    VotingEscrow escrow;
    GaugeFactory gaugeFactory;
    BribeFactory bribeFactory;
    Voter voter;
    RewardsDistributor distributor;
    Minter minter;
    TestOwner team;

    function setUp() public {
        vm.warp(block.timestamp + 1 weeks); // put some initial time in

        deployOwners();
        deployCoins();
        mintStables();
        uint256[] memory amountsVelo = new uint256[](2);
        amountsVelo[0] = 1e25;
        amountsVelo[1] = 1e25;
        mintVelo(owners, amountsVelo);
        team = new TestOwner();
        VeArtProxy artProxy = new VeArtProxy();
        escrow = new VotingEscrow(address(VELO), address(artProxy));
        factory = new PairFactory();
        router = new Router(address(factory), address(owner));
        gaugeFactory = new GaugeFactory();
        bribeFactory = new BribeFactory();
        voter = new Voter(
            address(escrow),
            address(factory),
            address(gaugeFactory),
            address(bribeFactory)
        );

        address[] memory tokens = new address[](2);
        tokens[0] = address(FRAX);
        tokens[1] = address(VELO);
        voter.initialize(tokens, address(owner));
        VELO.approve(address(escrow), TOKEN_1);
        escrow.create_lock(TOKEN_1, 4 * 365 * 86400);
        distributor = new RewardsDistributor(address(escrow));
        escrow.setVoter(address(voter));

        minter = new Minter(
            address(voter),
            address(escrow),
            address(distributor)
        );
        distributor.setDepositor(address(minter));
        VELO.setMinter(address(minter));

        VELO.approve(address(router), TOKEN_1);
        FRAX.approve(address(router), TOKEN_1);
        router.addLiquidity(
            address(FRAX),
            address(VELO),
            false,
            TOKEN_1,
            TOKEN_1,
            0,
            0,
            address(owner),
            block.timestamp
        );

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

        address[] memory claimants = new address[](1);
        claimants[0] = address(owner);
        uint256[] memory amountsToMint = new uint256[](1);
        amountsToMint[0] = TOKEN_1M;
        minter.initialize(claimants, amountsToMint, 15 * TOKEN_1M);
        assertEq(escrow.ownerOf(2), address(owner));
        assertEq(escrow.ownerOf(3), address(0));
        vm.roll(block.number + 1);
        assertEq(VELO.balanceOf(address(minter)), 14 * TOKEN_1M);

        uint256 before = VELO.balanceOf(address(owner));
        minter.update_period(); // initial period week 1
        uint256 after_ = VELO.balanceOf(address(owner));
        assertEq(minter.weekly(), 15 * TOKEN_1M);
        assertEq(after_ - before, 0);
        vm.warp(block.timestamp + 86400 * 7);
        vm.roll(block.number + 1);
        before = VELO.balanceOf(address(owner));
        minter.update_period(); // initial period week 2
        after_ = VELO.balanceOf(address(owner));
        assertLt(minter.weekly(), 15 * TOKEN_1M); // <15M for week shift
    }

    function testChangeTeam() public {
        // check that initial team is set to owner
        assertEq(minter.team(), address(owner));
        owner.setTeam(address(minter), address(owner2));
        owner2.acceptTeam(address(minter));

        assertEq(minter.team(), address(owner2));

        // expect revert from owner3 setting team
        vm.expectRevert(abi.encodePacked("not team"));
        owner3.setTeam(address(minter), address(owner));

        // expect revert from owner3 accepting team
        vm.expectRevert(abi.encodePacked("not pending team"));
        owner3.acceptTeam(address(minter));
    }

    function testTeamEmissionsRate() public {
        owner.setTeam(address(minter), address(team));
        team.acceptTeam(address(minter));

        vm.warp(block.timestamp + 86400 * 7);
        vm.roll(block.number + 1);
        uint256 beforeTeamSupply = VELO.balanceOf(address(team));
        uint256 weekly = minter.weekly_emission();
        uint256 growth = minter.calculate_growth(weekly);
        minter.update_period(); // new period
        uint256 afterTeamSupply = VELO.balanceOf(address(team));
        uint256 newTeamVelo = afterTeamSupply - beforeTeamSupply;
        assertEq(((weekly + growth + newTeamVelo) * 30) / 1000, newTeamVelo); // check 3% of new emissions to team

        vm.warp(block.timestamp + 86400 * 7);
        vm.roll(block.number + 1);
        beforeTeamSupply = VELO.balanceOf(address(team));
        weekly = minter.weekly_emission();
        growth = minter.calculate_growth(weekly);
        minter.update_period(); // new period
        afterTeamSupply = VELO.balanceOf(address(team));
        newTeamVelo = afterTeamSupply - beforeTeamSupply;
        assertEq(((weekly + growth + newTeamVelo) * 30) / 1000, newTeamVelo); // check 3% of new emissions to team

        // rate is right even when VELO is sent to Minter contract
        vm.warp(block.timestamp + 86400 * 7);
        vm.roll(block.number + 1);
        owner2.transfer(address(VELO), address(minter), 1e25);
        beforeTeamSupply = VELO.balanceOf(address(team));
        weekly = minter.weekly_emission();
        growth = minter.calculate_growth(weekly);
        minter.update_period(); // new period
        afterTeamSupply = VELO.balanceOf(address(team));
        newTeamVelo = afterTeamSupply - beforeTeamSupply;
        assertEq(((weekly + growth + newTeamVelo) * 30) / 1000, newTeamVelo); // check 3% of new emissions to team
    }

    function testChangeTeamEmissionsRate() public {
        owner.setTeam(address(minter), address(team));
        team.acceptTeam(address(minter));

        // expect revert from owner3 setting team
        vm.expectRevert(abi.encodePacked("not team"));
        owner3.setTeamEmissions(address(minter), 50);

        // expect revert for out-of-bounds rate
        vm.expectRevert(abi.encodePacked("rate too high"));
        team.setTeamEmissions(address(minter), 60);

        // new rate in bounds
        team.setTeamEmissions(address(minter), 50);

        vm.warp(block.timestamp + 86400 * 7);
        vm.roll(block.number + 1);
        uint256 beforeTeamSupply = VELO.balanceOf(address(team));
        uint256 weekly = minter.weekly_emission();
        uint256 growth = minter.calculate_growth(weekly);
        minter.update_period(); // new period
        uint256 afterTeamSupply = VELO.balanceOf(address(team));
        uint256 newTeamVelo = afterTeamSupply - beforeTeamSupply;
        assertEq(((weekly + growth + newTeamVelo) * 50) / 1000, newTeamVelo); // check 5% of new emissions to team
    }
}
