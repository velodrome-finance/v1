pragma solidity 0.8.13;

import "./BaseTest.sol";

contract RedeemTest is BaseTest {
    MerkleClaim claim;

    uint256 public constant redeemableUSDC = 10e6 * 1e6;
    uint256 public constant redeemableVELO = 10e6 * 1e18;

    function setUp() public {
        deployOwners();
        deployCoins();
        mintStables();

        claim = new MerkleClaim(
            address(VELO),
            0xd0aa6a4e5b4e13462921d7518eebdb7b297a7877d6cfe078b0c318827392fb55
        ); // root that mints User 100e18 tokens
        VELO.setMerkleClaim(address(claim));
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
