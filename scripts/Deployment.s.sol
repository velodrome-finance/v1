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
    address private constant WCANTO = 0x826551890Dc65655a0Aceca109aB11AbDbD7a07B;

    // privileged accounts
    address private constant COUNCIL = 0x06b16991B53632C2362267579AE7C4863c72fDb8;
    address private constant TEAM_MULTI_SIG = 0x13eeB8EdfF60BbCcB24Ec7Dd5668aa246525Dc51;
    address private constant GOVERNOR = 0x06b16991B53632C2362267579AE7C4863c72fDb8;
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
        new VelocimeterLibrary(address(router));

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
        pairFactory.setTank(TANK);

        // Set voting escrow's art proxy
        votingEscrow.setArtProxy(address(veArtProxy));

        // Set minter and voting escrow's team
        votingEscrow.setTeam(TEAM_MULTI_SIG);
        minter.setTeam(TEAM_MULTI_SIG);

        // Transfer pairfactory ownership to MSIG (team)
        pairFactory.transferOwnership(TEAM_MULTI_SIG);

        // Set voter's emergency council
        voter.setEmergencyCouncil(TEAM_MULTI_SIG);
        
        // Set voter's governor
        voter.setGovernor(TEAM_MULTI_SIG);

        // Set rewards distributor's depositor to minter contract
        rewardsDistributor.setDepositor(address(minter));

        // Initialize tokens for voter
        address[] memory whitelistedTokens = new address[](19);
        whitelistedTokens[0] = address(flow);
        whitelistedTokens[1] = 0x4e71A2E537B7f9D9413D3991D37958c0b5e1e503; // NOTE
        whitelistedTokens[2] = 0x80b5a32E4F032B2a058b4F29EC95EEfEEB87aDcd; // USDC
        whitelistedTokens[3] = 0x5db67696C3c088DfBf588d3dd849f44266ff0ffa; // CRE
        whitelistedTokens[4] = WCANTO;
        whitelistedTokens[5] = 0xecEEEfCEE421D8062EF8d6b4D814efe4dc898265; // ATOM
        whitelistedTokens[6] = 0x1D54EcB8583Ca25895c512A8308389fFD581F9c9; // INJ
        whitelistedTokens[7] = 0x3452e23F9c4cC62c70B7ADAd699B264AF3549C19; // CMDX
        whitelistedTokens[8] = 0xC5e00D3b04563950941f7137B5AfA3a534F0D6d6; // KAVA
        whitelistedTokens[9] = 0x5aD523d94Efb56C400941eb6F34393b84c75ba39; // AKT
        whitelistedTokens[10] = 0x0CE35b0D42608Ca54Eb7bcc8044f7087C18E7717; // OSMO
        whitelistedTokens[11] = 0x7264610A66EcA758A8ce95CF11Ff5741E1fd0455; // cINU
        whitelistedTokens[12] = 0xc03345448969Dd8C00e9E4A85d2d9722d093aF8E; // GRAV
        whitelistedTokens[13] = 0xFA3C22C069B9556A4B2f7EcE1Ee3B467909f4864; // SOMM
        whitelistedTokens[14] = 0x38D11B40D2173009aDB245b869e90525950aE345; // cBONK
        whitelistedTokens[15] = 0x5FD55A1B9FC24967C4dB09C513C3BA0DFa7FF687; // ETH
        whitelistedTokens[16] = 0xd567B3d7B8FE3C79a1AD8dA978812cfC4Fa05e75; // USDT
        whitelistedTokens[17] = 0x74ccbe53F77b08632ce0CB91D3A545bF6B8E0979; // fBOMB
        voter.initialize(whitelistedTokens, address(minter));

        vm.stopBroadcast();
    }
}
