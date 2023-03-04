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

        vm.stopBroadcast();
    }
}
