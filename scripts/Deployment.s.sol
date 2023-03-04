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
        address[] memory claimants = new claimants[]();
        uint256[] memory amounts = new amounts[]();

        // 1. Mint to Flow voter EOA
        claimants[0] = FLOW_VOTER_EOA;
        claimants[1] = FLOW_VOTER_EOA;
        claimants[2] = FLOW_VOTER_EOA;
        claimants[3] = FLOW_VOTER_EOA;
        claimants[4] = FLOW_VOTER_EOA;
        claimants[5] = FLOW_VOTER_EOA;
        claimants[6] = FLOW_VOTER_EOA;
        claimants[7] = FLOW_VOTER_EOA;
        claimants[8] = FLOW_VOTER_EOA;
        claimants[9] = FLOW_VOTER_EOA;
        claimants[10] = FLOW_VOTER_EOA;
        claimants[11] = FLOW_VOTER_EOA;
        claimants[12] = FLOW_VOTER_EOA;

        amounts[0] = ONE_MILLION;
        amounts[1] = ONE_MILLION;
        amounts[2] = ONE_MILLION;
        amounts[3] = ONE_MILLION;
        amounts[4] = ONE_MILLION;
        amounts[5] = TWO_MILLION;
        amounts[6] = TWO_MILLION;
        amounts[7] = TWO_MILLION;
        amounts[8] = TWO_MILLION;
        amounts[9] = TWO_MILLION;
        amounts[10] = FOUR_MILLION;
        amounts[11] = FOUR_MILLION;
        amounts[12] = FOUR_MILLION;

        // 2. Mint to team members
        claimants[13] = DUNKS;
        claimants[14] = T0RB1K;
        claimants[15] = T0RB1K;
        claimants[16] = T0RB1K;
        claimants[17] = CEAZOR;
        claimants[18] = CEAZOR;
        claimants[19] = CEAZOR;
        claimants[20] = MOTTO;
        claimants[21] = MOTTO;
        claimants[22] = MOTTO;
        claimants[22] = COOLIE;
        claimants[23] = COOLIE;
        claimants[24] = COOLIE;

        amounts[13] = FOUR_MILLION;
        amounts[14] = FOUR_MILLION;
        amounts[15] = FOUR_MILLION;
        amounts[16] = FOUR_MILLION;
        amounts[17] = FOUR_MILLION;
        amounts[18] = FOUR_MILLION;
        amounts[19] = FOUR_MILLION;
        amounts[20] = FOUR_MILLION;
        amounts[21] = FOUR_MILLION;
        amounts[22] = FOUR_MILLION;
        amounts[22] = FOUR_MILLION;
        amounts[23] = FOUR_MILLION;
        amounts[24] = FOUR_MILLION;

        minter.initialize(
            claimants,
            amounts,
            max
        );

        vm.stopBroadcast();
    }
}
