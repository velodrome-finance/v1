// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "openzeppelin-contracts/contracts/utils/math/Math.sol";

import "contracts/interfaces/IMinter.sol";
import "contracts/interfaces/IRewardsDistributor.sol";
import "contracts/interfaces/IFlow.sol";
import "contracts/interfaces/IVoter.sol";
import "contracts/interfaces/IVotingEscrow.sol";

// codifies the minting rules as per ve(3,3), abstracted from the token to support any token that allows minting

contract Minter is IMinter {
    uint256 internal constant WEEK = 86400 * 7; // allows minting once per week (reset every Thursday 00:00 UTC)
    uint256 internal constant EMISSION = 990;
    uint256 internal constant TAIL_EMISSION = 2;
    uint256 internal constant PRECISION = 1000;
    IFlow public immutable _flow;
    IVoter public immutable _voter;
    IVotingEscrow public immutable _ve;
    IRewardsDistributor public immutable _rewards_distributor;
    uint256 public weekly = 15_000_000 * 1e18; // represents a starting weekly emission of 15M FLOW (FLOW has 18 decimals)
    uint256 public active_period;
    uint256 internal constant LOCK = 86400 * 7 * 52 * 4;

    address internal initializer;
    address public team;
    address public pendingTeam;
    uint256 public teamRate;
    uint256 public constant MAX_TEAM_RATE = 50; // 5% max

    event Mint(
        address indexed sender,
        uint256 weekly,
        uint256 circulating_supply,
        uint256 circulating_emission
    );

    constructor(
        address __voter, // the voting & distribution system
        address __ve, // the ve(3,3) system that will be locked into
        address __rewards_distributor // the distribution system that ensures users aren't diluted
    ) {
        initializer = msg.sender;
        team = msg.sender;
        teamRate = 30; // 30 bps = 3%
        _flow = IFlow(IVotingEscrow(__ve).token());
        _voter = IVoter(__voter);
        _ve = IVotingEscrow(__ve);
        _rewards_distributor = IRewardsDistributor(__rewards_distributor);
        active_period = ((block.timestamp + (2 * WEEK)) / WEEK) * WEEK;
    }

    function initialize(
        address[] memory claimants, // partnerAddrs
        uint256[] memory amounts, // partnerAmounts
        uint256 max // sum amounts / max = % ownership of top protocols, so if initial 20m is distributed, and target is 25% protocol ownership, then max - 4 x 20m = 80m
    ) external {
        require(initializer == msg.sender);
        _flow.mint(address(this), max);
        _flow.approve(address(_ve), type(uint256).max);
        for (uint256 i = 0; i < claimants.length; i++) {
            _ve.create_lock_for(amounts[i], LOCK, claimants[i]);
        }
        initializer = address(0);
        active_period = ((block.timestamp) / WEEK) * WEEK; // allow minter.update_period() to mint new emissions THIS Thursday
    }

    function setTeam(address _team) external {
        require(msg.sender == team, "not team");
        pendingTeam = _team;
    }

    function acceptTeam() external {
        require(msg.sender == pendingTeam, "not pending team");
        team = pendingTeam;
    }

    function setTeamRate(uint256 _teamRate) external {
        require(msg.sender == team, "not team");
        require(_teamRate <= MAX_TEAM_RATE, "rate too high");
        teamRate = _teamRate;
    }

    // calculate circulating supply as total token supply - locked supply
    function circulating_supply() public view returns (uint256) {
        return _flow.totalSupply() - _ve.totalSupply();
    }

    // emission calculation is 1% of available supply to mint adjusted by circulating / total supply
    function calculate_emission() public view returns (uint256) {
        return (weekly * EMISSION) / PRECISION;
    }

    // weekly emission takes the max of calculated (aka target) emission versus circulating tail end emission
    function weekly_emission() public view returns (uint256) {
        return Math.max(calculate_emission(), circulating_emission());
    }

    // calculates tail end (infinity) emissions as 0.2% of total supply
    function circulating_emission() public view returns (uint256) {
        return (circulating_supply() * TAIL_EMISSION) / PRECISION;
    }

    // calculate inflation and adjust ve balances accordingly
    function calculate_growth(uint256 _minted) public view returns (uint256) {
        uint256 _veTotal = _ve.totalSupply();
        uint256 _flowTotal = _flow.totalSupply();
        return
            (((((_minted * _veTotal) / _flowTotal) * _veTotal) / _flowTotal) *
                _veTotal) /
            _flowTotal /
            2;
    }

    // update period can only be called once per cycle (1 week)
    function update_period() external returns (uint256) {
        uint256 _period = active_period;
        if (block.timestamp >= _period + WEEK && initializer == address(0)) {
            // only trigger if new week
            _period = (block.timestamp / WEEK) * WEEK;
            active_period = _period;
            weekly = weekly_emission();

            uint256 _growth = calculate_growth(weekly);
            uint256 _teamEmissions = (teamRate * (_growth + weekly)) /
                (PRECISION - teamRate);
            uint256 _required = _growth + weekly + _teamEmissions;
            uint256 _balanceOf = _flow.balanceOf(address(this));
            if (_balanceOf < _required) {
                _flow.mint(address(this), _required - _balanceOf);
            }

            require(_flow.transfer(team, _teamEmissions));
            require(_flow.transfer(address(_rewards_distributor), _growth));
            _rewards_distributor.checkpoint_token(); // checkpoint token balance that was just minted in rewards distributor
            _rewards_distributor.checkpoint_total_supply(); // checkpoint supply

            _flow.approve(address(_voter), weekly);
            _voter.notifyRewardAmount(weekly);

            emit Mint(
                msg.sender,
                weekly,
                circulating_supply(),
                circulating_emission()
            );
        }
        return _period;
    }
}
