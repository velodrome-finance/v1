// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// Scripting tool
import {Script} from "../lib/forge-std/src/Script.sol";

import {Minter} from "../contracts/Minter.sol";

contract InitialMintAndLock is Script {
    address private constant TEAM_MULTI_SIG = 0x13eeB8EdfF60BbCcB24Ec7Dd5668aa246525Dc51;

    // address to receive veNFT to be distributed to partners in the future
    address private constant FLOW_VOTER_EOA = 0xcC06464C7bbCF81417c08563dA2E1847c22b703a;
    address private constant ASSET_EOA = 0x1bae1083cf4125ed5deeb778985c1effac0ecc06;

    // team member addresses
    address private constant DUNKS = 0x069e85d4f1010dd961897dc8c095fbb5ff297434;
    address private constant T0RB1K = 0x0b776552c1aef1dc33005dd25acda22493b6615d;
    address private constant CEAZOR = 0x06b16991b53632c2362267579ae7c4863c72fdb8;
    address private constant MOTTO = 0x78e801136f77805239a7f533521a7a5570f572c8;
    address private constant COOLIE = 0x03b88dacb7c21b54cefecc297d981e5b721a9df1;

    // token amounts
    uint256 private constant ONE_MILLION = 1e24; // 1e24 == 1e6 (1m) ** 1e18 (decimals)
    uint256 private constant TWO_MILLION = 2e24; // 2e24 == 1e6 (1m) ** 1e18 (decimals)
    uint256 private constant FOUR_MILLION = 4e24; // 4e24 == 1e6 (1m) ** 1e18 (decimals)

    // time
    uint256 private constant ONE_YEAR = 31_536_000;
    uint256 private constant TWO_YEARS = 63_072_000;
    uint256 private constant FOUR_YEARS = 126_144_000;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // TODO: Fill address after mainnet deploy
        Minter minter = Minter(address(0));

        // Mint tokens and lock for veNFT

        // 1. Mint to Flow voter EOA
        Minter.Claim[] memory flowVoterEOAClaim1 = new Minter.Claim[](5);
        for (uint256 i; i < flowVoterEOAClaim1.length; i++) {
            flowVoterEOAClaim1[i] = Minter.Claim({claimant: FLOW_VOTER_EOA, amount: ONE_MILLION, lockTime: FOUR_YEARS});
        }
        minter.initialMintAndLock(flowVoterEOAClaim1, ONE_MILLION * flowVoterEOAClaim1.length);

        Minter.Claim[] memory flowVoterEOAClaim2 = new Minter.Claim[](5);
        for (uint256 i; i < flowVoterEOAClaim2.length; i++) {
            flowVoterEOAClaim2[i] = Minter.Claim({claimant: FLOW_VOTER_EOA, amount: TWO_MILLION, lockTime: FOUR_YEARS});
        }
        minter.initialMintAndLock(flowVoterEOAClaim2, TWO_MILLION * flowVoterEOAClaim2.length);

        Minter.Claim[] memory flowVoterEOAClaim3 = new Minter.Claim[](3);
        for (uint256 i; i < flowVoterEOAClaim3.length; i++) {
            flowVoterEOAClaim3[i] = Minter.Claim({claimant: FLOW_VOTER_EOA, amount: FOUR_MILLION, lockTime: FOUR_YEARS});
        }
        minter.initialMintAndLock(flowVoterEOAClaim3, FOUR_MILLION * flowVoterEOAClaim3.length);

        // 2. Mint to team members
        Minter.Claim[] memory dunksClaim = new Minter.Claim[](1);
        dunksClaim[0] = Minter.Claim({claimant: DUNKS, amount: FOUR_MILLION, lockTime: FOUR_YEARS});
        minter.initialMintAndLock(dunksClaim, FOUR_MILLION);

        Minter.Claim[] memory t0rb1kClaim = new Minter.Claim[](3);
        for (uint256 i; i < t0rb1kClaim.length; i++) {
            t0rb1kClaim[i] = Minter.Claim({claimant: T0RB1K, amount: FOUR_MILLION, lockTime: FOUR_YEARS});
        }
        minter.initialMintAndLock(t0rb1kClaim, FOUR_MILLION * t0rb1kClaim.length);

        Minter.Claim[] memory ceazorClaim = new Minter.Claim[](3);
        for (uint256 i; i < ceazorClaim.length; i++) {
            ceazorClaim[i] = Minter.Claim({claimant: CEAZOR, amount: FOUR_MILLION, lockTime: FOUR_YEARS});
        }
        minter.initialMintAndLock(ceazorClaim, FOUR_MILLION * ceazorClaim.length);

        Minter.Claim[] memory mottoClaim = new Minter.Claim[](3);
        for (uint256 i; i < mottoClaim.length; i++) {
            mottoClaim[i] = Minter.Claim({claimant: MOTTO, amount: FOUR_MILLION, lockTime: FOUR_YEARS});
        }
        minter.initialMintAndLock(mottoClaim, FOUR_MILLION * mottoClaim.length);

        Minter.Claim[] memory coolieClaim = new Minter.Claim[](3);
        for (uint256 i; i < coolieClaim.length; i++) {
            coolieClaim[i] = Minter.Claim({claimant: COOLIE, amount: FOUR_MILLION, lockTime: FOUR_YEARS});
        }
        minter.initialMintAndLock(coolieClaim, FOUR_MILLION * coolieClaim.length);

        // 3. TODO: Mint to snapshotted veNFT holders

        // 4. Mint for future partners
        Minter.Claim[] memory assetEOAClaim1 = new Minter.Claim[](3);
        for (uint256 i; i < assetEOAClaim1.length; i++) {
            assetEOAClaim1[i] = Minter.Claim({amount: FOUR_MILLION, claimant: ASSET_EOA, lockTime: FOUR_YEARS});
        }
        minter.initialMintAndLock(assetEOAClaim1, FOUR_MILLION * assetEOAClaim1.length);

        Minter.Claim[] memory multiSigClaim1 = new Minter.Claim[](13);
        for (uint256 i; i < multiSigClaim1.length; i++) {
            multiSigClaim1[i] = Minter.Claim({amount: FOUR_MILLION, claimant: TEAM_MULTI_SIG, lockTime: FOUR_YEARS});
        }
        minter.initialMintAndLock(multiSigClaim1, FOUR_MILLION * multiSigClaim1.length);

        Minter.Claim[] memory assetEOAClaim2 = new Minter.Claim[](3);
        for (uint256 i; i < assetEOAClaim2.length; i++) {
            assetEOAClaim2[i] = Minter.Claim({amount: TWO_MILLION, claimant: ASSET_EOA, lockTime: FOUR_YEARS});
        }
        minter.initialMintAndLock(assetEOAClaim1, TWO_MILLION * assetEOAClaim2.length);

        Minter.Claim[] memory multiSigClaim2 = new Minter.Claim[](15);
        for (uint256 i; i < multiSigClaim2.length; i++) {
            multiSigClaim2[i] = Minter.Claim({amount: TWO_MILLION, claimant: TEAM_MULTI_SIG, lockTime: FOUR_YEARS});
        }
        minter.initialMintAndLock(multiSigClaim2, TWO_MILLION * multiSigClaim2.length);

        Minter.Claim[] memory multiSigClaim3 = new Minter.Claim[](16);
        for (uint256 i; i < multiSigClaim3.length; i++) {
            multiSigClaim3[i] = Minter.Claim({amount: ONE_MILLION, claimant: TEAM_MULTI_SIG, lockTime: FOUR_YEARS});
        }
        minter.initialMintAndLock(multiSigClaim3, ONE_MILLION * multiSigClaim3.length);

        Minter.Claim[] memory assetEOAClaim3 = new Minter.Claim[](5);
        for (uint256 i; i < assetEOAClaim3.length; i++) {
            assetEOAClaim3[i] = Minter.Claim({amount: ONE_MILLION, claimant: ASSET_EOA, lockTime: TWO_YEARS});
        }
        minter.initialMintAndLock(assetEOAClaim3, ONE_MILLION * assetEOAClaim3.length);

        Minter.Claim[] memory assetEOAClaim4 = new Minter.Claim[](5);
        for (uint256 i; i < assetEOAClaim4.length; i++) {
            assetEOAClaim4[i] = Minter.Claim({amount: ONE_MILLION, claimant: ASSET_EOA, lockTime: ONE_YEAR});
        }
        minter.initialMintAndLock(assetEOAClaim4, ONE_MILLION * assetEOAClaim4.length);

        // set initializer to 0 so we can no longer mint more
        minter.startActivePeriod();

        vm.stopBroadcast();
    }
}
