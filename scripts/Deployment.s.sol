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

        // Set pair factory pauser and tank
        pairFactory.setPauser(TEAM_MULTI_SIG);
        pairFactory.setTank(TANK);

        // Set voting escrow's voter and art proxy
        votingEscrow.setVoter(address(voter));
        votingEscrow.setArtProxy(address(veArtProxy));

        // Set minter and voting escrow's team
        votingEscrow.setTeam(TEAM_MULTI_SIG);
        minter.setTeam(TEAM_MULTI_SIG);
        pairFactory.setTeam(TEAM_MULTI_SIG);

        // Set fee manager
        pairFactory.setFeeManager(TEAM_MULTI_SIG);

        // Set voter's governor
        voter.setGovernor(TEAM_MULTI_SIG);

        // Set voter's emergency council
        voter.setEmergencyCouncil(TEAM_MULTI_SIG);

        // Set rewards distributor's depositor to minter contract
        rewardsDistributor.setDepositor(address(minter));

        // Initialize tokens for voter
        address[] memory whitelistedTokens = new address[](19);
        whitelistedTokens[0] = address(flow);
        whitelistedTokens[1] = 0x4e71a2e537b7f9d9413d3991d37958c0b5e1e503; // NOTE
        whitelistedTokens[2] = 0x80b5a32e4f032b2a058b4f29ec95eefeeb87adcd; // USDC
        whitelistedTokens[3] = 0x5db67696c3c088dfbf588d3dd849f44266ff0ffa; // CRE
        whitelistedTokens[4] = WCANTO;
        whitelistedTokens[5] = 0xeceeefcee421d8062ef8d6b4d814efe4dc898265; // ATOM
        whitelistedTokens[6] = 0x1d54ecb8583ca25895c512a8308389ffd581f9c9; // INJ
        whitelistedTokens[7] = 0x3452e23f9c4cc62c70b7adad699b264af3549c19; // CMDX
        whitelistedTokens[8] = 0xc5e00d3b04563950941f7137b5afa3a534f0d6d6; // KAVA
        whitelistedTokens[9] = 0x5ad523d94efb56c400941eb6f34393b84c75ba39; // AKT
        whitelistedTokens[10] = 0x0ce35b0d42608ca54eb7bcc8044f7087c18e7717; // OSMO
        whitelistedTokens[11] = 0xe832c073b1b665e21150ac70fa7c798d9926ccf1; // WAIT
        whitelistedTokens[12] = 0x7264610a66eca758a8ce95cf11ff5741e1fd0455; // cINU
        whitelistedTokens[13] = 0xc03345448969dd8c00e9e4a85d2d9722d093af8e; // GRAV
        whitelistedTokens[14] = 0xfa3c22c069b9556a4b2f7ece1ee3b467909f4864; // SOMM
        whitelistedTokens[15] = 0x38d11b40d2173009adb245b869e90525950ae345; // cBONK
        whitelistedTokens[16] = 0x5FD55A1B9FC24967C4dB09C513C3BA0DFa7FF687; // ETH
        whitelistedTokens[17] = 0xd567B3d7B8FE3C79a1AD8dA978812cfC4Fa05e75; // USDT
        whitelistedTokens[18] = 0x74ccbe53F77b08632ce0CB91D3A545bF6B8E0979; // fBOMB
        voter.initialize(whitelistedTokens, address(minter));

        vm.stopBroadcast();
    }
}
