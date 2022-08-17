// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "openzeppelin-contracts/contracts/governance/Governor.sol";
import "openzeppelin-contracts/contracts/governance/extensions/GovernorVotes.sol";
import "openzeppelin-contracts/contracts/governance/extensions/GovernorCountingSimple.sol";
import "openzeppelin-contracts/contracts/governance/extensions/GovernorVotesQuorumFraction.sol";

contract TestGovernance is
    Governor,
    GovernorVotes,
    GovernorCountingSimple,
    GovernorVotesQuorumFraction
{
    constructor(IVotes _token)
        Governor("TestGovernor")
        GovernorVotes(_token)
        GovernorVotesQuorumFraction(4)
    {}

    function votingDelay() public pure override returns (uint256) {
        return 1;
    }

    function votingPeriod() public pure override returns (uint256) {
        return 7;
    }

    function proposalThreshold() public pure override returns (uint256) {
        return 0;
    }

    function wow() public pure returns (uint256) {
        return 1;
    }
}
