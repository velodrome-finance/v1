pragma solidity 0.8.13;

import "./BaseTest.sol";
import "contracts/VeloGovernor.sol";

contract VeloGovernorTest is BaseTest {
    VotingEscrow escrow;
    GaugeFactory gaugeFactory;
    BribeFactory bribeFactory;
    Voter voter;
    RewardsDistributor distributor;
    Minter minter;
    Gauge gauge;
    InternalBribe bribe;
    VeloGovernor governor;

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

        VELO.approve(address(escrow), 97 * TOKEN_1);
        escrow.create_lock(97 * TOKEN_1, 4 * 365 * 86400);
        vm.roll(block.number + 1);

        // owner2 owns less than quorum, 3%
        vm.startPrank(address(owner2));
        VELO.approve(address(escrow), 3 * TOKEN_1);
        escrow.create_lock(3 * TOKEN_1, 4 * 365 * 86400);
        vm.roll(block.number + 1);
        vm.stopPrank();

        deployPairFactoryAndRouter();

        USDC.approve(address(router), USDC_100K);
        FRAX.approve(address(router), TOKEN_100K);
        router.addLiquidity(address(FRAX), address(USDC), true, TOKEN_100K, USDC_100K, TOKEN_100K, USDC_100K, address(owner), block.timestamp);

        gaugeFactory = new GaugeFactory();
        bribeFactory = new BribeFactory();
        voter = new Voter(address(escrow), address(factory), address(gaugeFactory), address(bribeFactory));

        escrow.setVoter(address(voter));

        distributor = new RewardsDistributor(address(escrow));

        minter = new Minter(address(voter), address(escrow), address(distributor));
        distributor.setDepositor(address(minter));
        VELO.setMinter(address(minter));

        VELO.approve(address(gaugeFactory), 15 * TOKEN_100K);
        voter.createGauge(address(pair));
        address gaugeAddress = voter.gauges(address(pair));
        address bribeAddress = voter.internal_bribes(gaugeAddress);
        gauge = Gauge(gaugeAddress);
        bribe = InternalBribe(bribeAddress);

        governor = new VeloGovernor(escrow);
        voter.setGovernor(address(governor));
    }

    function testGovernorCanWhitelistTokens(address token) public {
        vm.startPrank(address(governor));
        voter.whitelist(token);
        vm.stopPrank();
    }

    function testFailNonGovernorCannotWhitelistTokens(address user, address token) public {
        vm.assume(user != address(governor));

        vm.startPrank(address(user));
        voter.whitelist(token);
        vm.stopPrank();
    }

    function testGovernorCanCreateGaugesForAnyAddress(address a) public {
        vm.assume(a != address(0));

        vm.startPrank(address(governor));
        voter.createGauge(a);
        vm.stopPrank();
    }

    function testVeVeloMergesAutoDelegates() public {
        // owner2 + owner3 > quorum
        vm.startPrank(address(owner3));
        VELO.approve(address(escrow), 3 * TOKEN_1);
        escrow.create_lock(3 * TOKEN_1, 4 * 365 * 86400);
        vm.roll(block.number + 1);
        uint256 pre2 = escrow.getVotes(address(owner2));
        uint256 pre3 = escrow.getVotes(address(owner3));

        // merge
        escrow.approve(address(owner2), 3);
        escrow.transferFrom(address(owner3), address(owner2), 3);
        vm.stopPrank();
        vm.startPrank(address(owner2));
        escrow.merge(3, 2);
        vm.stopPrank();

        // assert vote balances
        uint256 post2 = escrow.getVotes(address(owner2));
        assertApproxEqAbs(
            pre2 + pre3,
            post2,
            4 * 365 * 86400 // merge rounds down time lock
        );
    }

    function testFailCannotProposeWithoutSufficientBalance() public {
        // propose
        vm.startPrank(address(owner3));
        address[] memory targets = new address[](1);
        targets[0] = address(voter);
        uint256[] memory values = new uint256[](1);
        values[0] = 0;
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSelector(voter.whitelist.selector, address(USDC));
        string memory description = "Whitelist USDC";

        governor.propose(targets, values, calldatas, description);
        vm.stopPrank();
    }

    function testFailProposalsNeedQuorumToPass() public {
        assertFalse(voter.isWhitelisted(address(USDC)));

        address[] memory targets = new address[](1);
        targets[0] = address(voter);
        uint256[] memory values = new uint256[](1);
        values[0] = 0;
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSelector(voter.whitelist.selector, address(USDC));
        string memory description = "Whitelist USDC";

        // propose
        vm.startPrank(address(owner));
        uint256 pid = governor.propose(targets, values, calldatas, description);
        vm.warp(block.timestamp + 16 minutes); // delay
        vm.stopPrank();

        // vote
        vm.startPrank(address(owner2));
        governor.castVote(pid, 1);
        vm.warp(block.timestamp + 1 weeks); // voting period
        vm.stopPrank();

        // execute
        vm.startPrank(address(owner));
        governor.execute(targets, values, calldatas, keccak256(bytes(description)));
        vm.stopPrank();
    }

    function testProposalHasQuorum() public {
        assertFalse(voter.isWhitelisted(address(USDC)));

        address[] memory targets = new address[](1);
        targets[0] = address(voter);
        uint256[] memory values = new uint256[](1);
        values[0] = 0;
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSelector(voter.whitelist.selector, address(USDC));
        string memory description = "Whitelist USDC";

        // propose
        vm.startPrank(address(owner));
        uint256 pid = governor.propose(targets, values, calldatas, description);
        vm.warp(block.timestamp + 16 minutes); // delay
        vm.stopPrank();

        // vote
        vm.startPrank(address(owner));
        governor.castVote(pid, 1);
        vm.warp(block.timestamp + 1 weeks); // voting period
        vm.stopPrank();

        // execute
        vm.startPrank(address(owner));
        governor.execute(targets, values, calldatas, keccak256(bytes(description)));
        vm.stopPrank();

        assertTrue(voter.isWhitelisted(address(USDC)));
    }
}
