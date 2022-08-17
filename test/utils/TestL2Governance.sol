// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "contracts/governance/L2Governor.sol";
import "contracts/governance/L2GovernorVotes.sol";
import "contracts/governance/L2GovernorCountingSimple.sol";
import "contracts/governance/L2GovernorVotesQuorumFraction.sol";

contract TestL2Governance is
    L2Governor,
    L2GovernorVotes,
    L2GovernorCountingSimple,
    L2GovernorVotesQuorumFraction
{
    constructor(IVotes _token)
        L2Governor("TestL2Governor")
        L2GovernorVotes(_token)
        L2GovernorVotesQuorumFraction(4)
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
}
