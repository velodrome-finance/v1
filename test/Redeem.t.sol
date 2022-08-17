pragma solidity 0.8.13;

import "./BaseTest.sol";
import "utils/TestEndpoint.sol";

contract RedeemTest is BaseTest {
    TestEndpoint endpoint;
    RedemptionSender sender;
    RedemptionReceiver receiver;
    MerkleClaim claim;

    uint256 public constant redeemableUSDC = 10e6 * 1e6;
    uint256 public constant redeemableVELO = 10e6 * 1e18;

    function setUp() public {
        deployOwners();
        deployCoins();
        mintStables();

        endpoint = new TestEndpoint(12); // mock LZ endpoint sending from Fantom
        receiver = new RedemptionReceiver(
            address(USDC),
            address(VELO),
            12,
            address(endpoint)
        );
        sender = new RedemptionSender(
            address(WEVE),
            11,
            address(endpoint),
            address(receiver)
        );

        USDC.mint(address(this), redeemableUSDC);
        USDC.approve(address(receiver), redeemableUSDC);

        VELO.setRedemptionReceiver(address(receiver));
        receiver.initializeReceiverWith(
            address(sender),
            redeemableUSDC,
            redeemableVELO
        );

        claim = new MerkleClaim(
            address(VELO),
            0xd0aa6a4e5b4e13462921d7518eebdb7b297a7877d6cfe078b0c318827392fb55
        ); // root that mints User 100e18 tokens
        VELO.setMerkleClaim(address(claim));
    }

    function testRedemption(address redeemer, uint128 amount) public {
        vm.assume(redeemer != address(0) && redeemer != address(owner) && 1 < amount && amount < sender.ELIGIBLE_WEVE());

        uint256 beforeUSDC = USDC.balanceOf(redeemer);

        WEVE.mint(redeemer, amount);
        vm.startPrank(redeemer);
        WEVE.approve(address(sender), amount);
        sender.redeemWEVE(amount / 2, address(0), bytes(""));
        sender.redeemWEVE(amount / 2, address(0), bytes(""));
        vm.stopPrank();

        assertApproxEqAbs(
            USDC.balanceOf(redeemer) - beforeUSDC,
            (amount * redeemableUSDC) / sender.ELIGIBLE_WEVE(),
            1
        );

        // check that team can't claim
        vm.expectRevert(abi.encodePacked("LEFTOVERS_NOT_CLAIMABLE"));
        receiver.claimLeftovers();

        // fwd 1 month
        vm.warp(block.timestamp + 30 days);

        // check that not anyone can claim
        vm.startPrank(address(receiver));
        vm.expectRevert(abi.encodePacked("ONLY_TEAM"));
        receiver.claimLeftovers();
        vm.stopPrank();

        // check that team can claim
        assertGt(USDC.balanceOf(address(receiver)), 0);

        receiver.claimLeftovers();

        assertEq(USDC.balanceOf(address(receiver)), 0);
    }

    function testClaimAirdrop() public {
        address user = 0x185a4dc360CE69bDCceE33b3784B0282f7961aea;

        // Setup correct proof
        bytes32[] memory proof = new bytes32[](1);
        proof[0] = 0xceeae64152a2deaf8c661fccd5645458ba20261b16d2f6e090fe908b0ac9ca88;

        // Collect balance of tokens before claim
        uint256 preBalance = VELO.balanceOf(user);

        // Claim tokens
        vm.startPrank(user);
        claim.claim(
            // Claiming for user
            user,
            // 100 tokens
            100e18,
            // With valid proof
            proof
        );

        // Collect balance of tokens after claim
        uint256 postBalance = VELO.balanceOf(user);

        // Assert balance before + 100 tokens = after balance
        assertEq(postBalance, preBalance + 100e18);
    }
}
