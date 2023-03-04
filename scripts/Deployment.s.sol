// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// Scripting tool
import {Script} from "../lib/forge-std/src/Script.sol";

import {Flow} from "../contracts/Flow.sol";
import {GaugeFactory} from "../contracts/factories/GaugeFactory.sol";
import {BribeFactory} from "../contracts/factories/BribeFactory.sol";
import {PairFactory} from "../contracts/factories/PairFactory.sol";
import {WrappedExternalBribeFactory} from "../contracts/factories/WrappedExternalBribeFactory.sol";
import {Router} from "../contracts/Router.sol";
import {VelocimeterLibrary} from "../contracts/VelocimeterLibrary.sol";
import {VeArtProxy} from "../contracts/VeArtProxy.sol";
import {VotingEscrow} from "../contracts/VotingEscrow.sol";
import {RewardsDistributor} from "../contracts/RewardsDistributor.sol";
import {Voter} from "../contracts/Voter.sol";
import {Minter} from "../contracts/Minter.sol";

contract Deployment is Script {
    // token addresses
    address private constant WCANTO = 0x826551890dc65655a0aceca109ab11abdbd7a07b;

    // privileged accounts
    address private constant COUNCIL = 0x06b16991b53632c2362267579ae7c4863c72fdb8;
    address private constant TEAM_MULTI_SIG = 0x13eeB8EdfF60BbCcB24Ec7Dd5668aa246525Dc51;
    address private constant GOVERNOR = 0x06b16991b53632c2362267579ae7c4863c72fdb8;
    address private constant TANK = 0x0A868fd1523a1ef58Db1F2D135219F0e30CBf7FB;

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

        // Flow token
        Flow flow = new Flow({initialSupplyRecipient: address(this)});

        // Gauge factory
        GaugeFactory gaugeFactory = new GaugeFactory();

        // Bribe factory
        BribeFactory bribeFactory = new BribeFactory();

        // Pair factory
        PairFactory pairFactory = new PairFactory();

        // Router
        Router router = new Router(address(pairFactory), WCANTO);

        // VelocimeterLibrary
        VelocimeterLibrary velocimeterLib = new VelocimeterLibrary(address(router));

        // VeArtProxy
        VeArtProxy veArtProxy = new VeArtProxy();

        // VotingEscrow
        VotingEscrow votingEscrow = new VotingEscrow(address(flow), address(veArtProxy), TEAM_MULTI_SIG);

        // RewardsDistributor
        RewardsDistributor rewardsDistributor = new RewardsDistributor(address(votingEscrow));

        // Wrapped external bribe factory
        WrappedExternalBribeFactory wrappedExternalBribeFactory = new WrappedExternalBribeFactory();

        // Voter
        Voter voter = new Voter(
            address(votingEscrow),
            address(pairFactory),
            address(gaugeFactory),
            address(bribeFactory),
            address(wrappedExternalBribeFactory)
        );

        // Set voter
        wrappedExternalBribeFactory.setVoter(address(voter));
        votingEscrow.setVoter(address(voter));
        pairFactory.setVoter(address(voter));

        // Minter
        Minter minter = new Minter(
            address(voter),
            address(votingEscrow),
            address(rewardsDistributor)
        );
        // TODO: Minter.initialize, Minter.setTeam

        // Set flow minter to contract
        flow.setMinter(address(minter));

        // Set pair factory pauser
        pairFactory.setPauser(TEAM_MULTI_SIG);

        // Set voting escrow's voter
        votingEscrow.setVoter(address(voter));

        // Set minter and voting escrow's team
        votingEscrow.setTeam(TEAM_MULTI_SIG);
        minter.setTeam(TEAM_MULTI_SIG);

        // Set voter's governor
        voter.setGovernor(TEAM_MULTI_SIG);

        // Set voter's emergency council
        voter.setEmergencyCouncil(TEAM_MULTI_SIG);

        // Set rewards distributor's depositor to minter contract
        rewardsDistributor.setDepositor(address(minter));

        // Initialize tokens for voter
        // TODO: Get all the whitelisted tokens
        address[] memory whitelistedTokens = new address[](2);
        whitelistedTokens[0] = address(flow);
        voter.initialize(whitelistedTokens, address(minter));

        // Mint tokens and lock for veNFT
        Minter.Claim[] memory claims = new Minter.Claim[](30);

        // 1. Mint to Flow voter EOA
        for (uint256 i = 0; i <= 4; i++) {
            claims[i] = Minter.Claim({claimant: FLOW_VOTER_EOA, amount: ONE_MILLION, lockTime: FOUR_YEARS});
        }

        for (uint256 i = 5; i <= 9; i++) {
            claims[i] = Minter.Claim({claimant: FLOW_VOTER_EOA, amount: TWO_MILLION, lockTime: FOUR_YEARS});
        }

        for (uint256 i = 10; i <= 12; i++) {
            claims[i] = Minter.Claim({claimant: FLOW_VOTER_EOA, amount: FOUR_MILLION, lockTime: FOUR_YEARS});
        }

        // 2. Mint to team members
        claims[13] = Minter.Claim({claimant: DUNKS, amount: FOUR_MILLION, lockTime: FOUR_YEARS});

        for (uint256 i = 14; i <= 16; i++) {
            claims[i] = Minter.Claim({claimant: T0RB1K, amount: FOUR_MILLION, lockTime: FOUR_YEARS});
        }

        for (uint256 i = 17; i <= 19; i++) {
            claims[i] = Minter.Claim({claimant: CEAZOR, amount: FOUR_MILLION, lockTime: FOUR_YEARS});
        }

        for (uint256 i = 20; i <= 22; i++) {
            claims[i] = Minter.Claim({claimant: MOTTO, amount: FOUR_MILLION, lockTime: FOUR_YEARS});
        }

        for (uint256 i = 23; i <= 25; i++) {
            claims[i] = Minter.Claim({claimant: COOLIE, amount: FOUR_MILLION, lockTime: FOUR_YEARS});
        }

        // 3. Mint to snapshotted veNFT holders

        // 4. Mint for future partners
        for (uint256 i = 26; i <= 28; i++) {
            claims[i] = Minter.Claim({amount: FOUR_MILLION, claimant: ASSET_EOA, lockTime: FOUR_YEARS});
        }

        for (uint256 i = 29; i <= 42; i++) {
            claims[i] = Minter.Claim({amount: FOUR_MILLION, claimant: TEAM_MULTI_SIG, lockTime: FOUR_YEARS});
        }

        for (uint256 i = 43; i <= 45; i++) {
            claims[i] = Minter.Claim({amount: TWO_MILLION, claimant: ASSET_EOA, lockTime: FOUR_YEARS});
        }

        for (uint256 i = 46; i <= 60; i++) {
            claims[i] = Minter.Claim({amount: TWO_MILLION, claimant: TEAM_MULTI_SIG, lockTime: FOUR_YEARS});
        }

        for (uint256 i = 61; i <= 76; i++) {
            claims[i] = Minter.Claim({amount: ONE_MILLION, claimant: TEAM_MULTI_SIG, lockTime: FOUR_YEARS});
        }

        for (uint256 i = 77; i <= 81; i++) {
            claims[i] = Minter.Claim({amount: ONE_MILLION, claimant: ASSET_EOA, lockTime: TWO_YEARS});
        }

        for (uint256 i = 82; i <= 86; i++) {
            claims[i] = Minter.Claim({amount: ONE_MILLION, claimant: ASSET_EOA, lockTime: ONE_YEAR});
        }

        minter.initialize(
            claimants,
            amounts,
            max
        );
        minter.startActivePeriod();

        vm.stopBroadcast();
    }
}
