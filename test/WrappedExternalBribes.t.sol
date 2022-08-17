pragma solidity 0.8.13;

import './BaseTest.sol';
import "contracts/WrappedExternalBribe.sol";
import "contracts/factories/WrappedExternalBribeFactory.sol";

contract WrappedExternalBribesTest is BaseTest {
    VotingEscrow escrow;
    GaugeFactory gaugeFactory;
    BribeFactory bribeFactory;
    WrappedExternalBribeFactory wxbribeFactory;
    Voter voter;
    RewardsDistributor distributor;
    Minter minter;
    Gauge gauge;
    InternalBribe bribe;
    ExternalBribe xbribe;
    WrappedExternalBribe wxbribe;

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
        wxbribeFactory = new WrappedExternalBribeFactory(address(voter));

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
        wxbribe = WrappedExternalBribe(wxbribeFactory.createBribe(address(xbribe)));

        // ve
        VELO.approve(address(escrow), TOKEN_1);
        escrow.create_lock(TOKEN_1, 4 * 365 * 86400);
        vm.startPrank(address(owner2));
        VELO.approve(address(escrow), TOKEN_1);
        escrow.create_lock(TOKEN_1, 4 * 365 * 86400);
        vm.warp(block.timestamp + 1);
        vm.stopPrank();
    }

    function testOldBribesAreBroken() public {
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
        // twice
        xbribe.getRewardForOwner(1, rewards);
        vm.stopPrank();

        uint256 post = LR.balanceOf(address(owner));
        assertEq(post - pre, TOKEN_1);
    }

    function testWrappedBribesCanClaimOnlyOnce() public {
        vm.warp(block.timestamp + 1 weeks / 2);

        // create a bribe
        LR.approve(address(wxbribe), TOKEN_1);
        wxbribe.notifyRewardAmount(address(LR), TOKEN_1);

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
        uint256 earned = wxbribe.earned(address(LR), 1);
        assertEq(earned, TOKEN_1 / 2);

        // rewards
        address[] memory rewards = new address[](1);
        rewards[0] = address(LR);

        vm.startPrank(address(voter));
        // once
        wxbribe.getRewardForOwner(1, rewards);
        uint256 post = LR.balanceOf(address(owner));
        // twice
        wxbribe.getRewardForOwner(1, rewards);
        vm.stopPrank();

        uint256 post_post = LR.balanceOf(address(owner));
        assertEq(post_post, post);
        assertEq(post_post - pre, TOKEN_1 / 2);
    }

    function testWrappedBribesCanClaimOnlyOnceArray() public {
        vm.warp(block.timestamp + 1 weeks / 2);

        // create a bribe
        LR.approve(address(wxbribe), TOKEN_1);
        wxbribe.notifyRewardAmount(address(LR), TOKEN_1);

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
        uint256 earned = wxbribe.earned(address(LR), 1);
        assertEq(earned, TOKEN_1 / 2);

        // rewards
        address[] memory rewards = new address[](2);
        rewards[0] = address(LR);
        rewards[1] = address(LR);

        vm.startPrank(address(voter));
        // once
        wxbribe.getRewardForOwner(1, rewards);
        uint256 post = LR.balanceOf(address(owner));
        // twice
        wxbribe.getRewardForOwner(1, rewards);
        vm.stopPrank();

        uint256 post_post = LR.balanceOf(address(owner));
        assertEq(post_post, post);
        assertEq(post_post - pre, TOKEN_1 / 2);
    }
}