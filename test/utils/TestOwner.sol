pragma solidity 0.8.13;

import "solmate/test/utils/mocks/MockERC20.sol";
import "contracts/redeem/RedemptionSender.sol";
import "contracts/Gauge.sol";
import "contracts/Minter.sol";
import "contracts/Pair.sol";
import "contracts/Router.sol";
import "contracts/Velo.sol";
import "contracts/VotingEscrow.sol";
import "utils/TestStakingRewards.sol";
import "utils/TestVotingEscrow.sol";

contract TestOwner {
    /*//////////////////////////////////////////////////////////////
                               MockERC20
    //////////////////////////////////////////////////////////////*/

    function approve(address _token, address _spender, uint256 _amount) public {
        MockERC20(_token).approve(_spender, _amount);
    }

    function transfer(address _token, address _to, uint256 _amount) public {
        MockERC20(_token).transfer(_to, _amount);
    }

    /*//////////////////////////////////////////////////////////////
                             RedemptionSender
    //////////////////////////////////////////////////////////////*/

    function redeemWEVE(address _sender, uint256 _amount) public {
        RedemptionSender(_sender).redeemWEVE(_amount, address(0), bytes(''));
    }

    /*//////////////////////////////////////////////////////////////
                                  Pair
    //////////////////////////////////////////////////////////////*/

    function claimFees(address _pair) public {
        Pair(_pair).claimFees();
    }

    function mint(address _pair, address _to) public {
        Pair(_pair).mint(_to);
    }

    function getAmountOut(address _pair, uint256 _amountIn, address _tokenIn) public view returns (uint256) {
        return Pair(_pair).getAmountOut(_amountIn, _tokenIn);
    }

    /*//////////////////////////////////////////////////////////////
                               PairFactory
    //////////////////////////////////////////////////////////////*/

    function setFeeManager(address _factory, address _feeManager) public {
        PairFactory(_factory).setFeeManager(_feeManager);
    }

    function acceptFeeManager(address _factory) public {
        PairFactory(_factory).acceptFeeManager();
    }

    function setFee(address _factory, bool _stable, uint256 _fee) public {
        PairFactory(_factory).setFee(_stable, _fee);
    }

    /*//////////////////////////////////////////////////////////////
                                Router
    //////////////////////////////////////////////////////////////*/

    function addLiquidity(address payable _router, address _tokenA, address _tokenB, bool _stable, uint256 _amountADesired, uint256 _amountBDesired, uint256 _amountAMin, uint256 _amountBMin, address _to, uint256 _deadline) public {
        Router(_router).addLiquidity(_tokenA, _tokenB, _stable, _amountADesired, _amountBDesired, _amountAMin, _amountBMin, _to, _deadline);
    }

    function addLiquidityETH(address payable _router, address _token, bool _stable, uint256 _amountTokenDesired, uint256 _amountTokenMin, uint256 _amountETHMin, address _to, uint256 _deadline) public payable {
        Router(_router).addLiquidityETH{value: msg.value}(_token, _stable, _amountTokenDesired, _amountTokenMin, _amountETHMin, _to, _deadline);
    }

    function swapExactTokensForTokens(address payable _router, uint256 _amountIn, uint256 _amountOutMin, Router.route[] calldata _routes, address _to, uint256 _deadline) public {
        Router(_router).swapExactTokensForTokens(_amountIn, _amountOutMin, _routes, _to, _deadline);
    }

    /*//////////////////////////////////////////////////////////////
                              VotingEscrow
    //////////////////////////////////////////////////////////////*/

    function transferFrom(address _escrow, address _from, address _to, uint256 _tokenId) public {
        VotingEscrow(_escrow).transferFrom(_from, _to, _tokenId);
    }

    function approveEscrow(address _escrow, address _approved, uint _tokenId) public {
        VotingEscrow(_escrow).approve(_approved, _tokenId);
    }

    function merge(address _escrow, uint256 _from, uint _to) public {
        VotingEscrow(_escrow).merge(_from, _to);
    }

    function create_lock(address _escrow, uint256 _amount, uint256 _duration) public {
        TestVotingEscrow(_escrow).create_lock(_amount, _duration);
    }

    /*//////////////////////////////////////////////////////////////
                                 Minter
    //////////////////////////////////////////////////////////////*/

    function setTeam(address _minter, address _team) public {
        Minter(_minter).setTeam(_team);
    }

    function acceptTeam(address _minter) public {
        Minter(_minter).acceptTeam();
    }

    function setTeamEmissions(address _minter, uint256 _rate) public {
        Minter(_minter).setTeamRate(_rate);
    }

    /*//////////////////////////////////////////////////////////////
                                 Gauge
    //////////////////////////////////////////////////////////////*/

    function getGaugeReward(address _gauge, address _account, address[] memory _tokens) public {
        Gauge(_gauge).getReward(_account, _tokens);
    }

    function deposit(address _gauge, uint256 _amount, uint256 _tokenId) public {
        Gauge(_gauge).deposit(_amount, _tokenId);
    }

    function withdrawGauge(address _gauge, uint256 _amount) public {
        Gauge(_gauge).withdraw(_amount);
    }

    /*//////////////////////////////////////////////////////////////
                              StakingRewards
    //////////////////////////////////////////////////////////////*/

    function stakeStake(address _staking, uint256 _amount) public {
        TestStakingRewards(_staking).stake(_amount);
    }

    function withdrawStake(address _staking, uint256 _amount) public {
        TestStakingRewards(_staking).withdraw(_amount);
    }

    function getStakeReward(address _staking) public {
        TestStakingRewards(_staking).getReward();
    }
}
