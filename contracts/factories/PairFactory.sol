// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import 'contracts/interfaces/IPairFactory.sol';
import 'contracts/Pair.sol';
import "openzeppelin-contracts/contracts/access/Ownable.sol";


contract PairFactory is IPairFactory, Ownable {

    bool public isPaused;
    address public pendingPauser;
    uint256 public stableFee;
    uint256 public volatileFee;
    uint256 public constant MAX_FEE = 50; // 0.5%
    address public voter;
    address public tank;
    address public deployer;

    mapping(address => mapping(address => mapping(bool => address))) public getPair;
    address[] public allPairs;
    mapping(address => bool) public isPair; // simplified check if its a pair, given that `stable` flag might not be available in peripherals

    address internal _temp0;
    address internal _temp1;
    bool internal _temp;

    event PairCreated(address indexed token0, address indexed token1, bool stable, address pair, uint);
    event TeamSet(address indexed setter, address indexed team);
    event VoterSet(address indexed setter, address indexed voter);
    event TankSet(address indexed setter, address indexed tank);
    event PauserSet(address indexed setter, address indexed pauser);
    event PauserAccepted(address indexed previous, address indexed current);
    event Paused(address indexed pauser, bool paused);
    event FeeManagerSet(address indexed setter, address indexed feeManager);
    event FeeManagerAccepted(address indexed previous, address indexed current);

    event FeeSet(address indexed setter, bool stable, uint256 fee);

    constructor() {
        pauser = msg.sender;
        isPaused = false;
        feeManager = msg.sender;
        stableFee = 3; // 0.03%
        volatileFee = 25; // 0.25%
        deployer = msg.sender;
    }


    function setVoter(address _voter) external {
        require(voter == address(0), 'The voter has already been set.');
        require(msg.sender == deployer, 'Not authorised to set voter.'); // have to make sure that this can be set to the voter address during init script
        voter = _voter;
        emit VoterSet(msg.sender, _voter);
    }

    function setTank(address _tank) external onlyOwner {
        tank = _tank;
        emit TankSet(msg.sender, _tank);
    }

    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

    function setPause(bool _state) external onlyOwner {
        isPaused = _state;
        emit Paused(msg.sender, _state);
    }

    function setFee(bool _stable, uint256 _fee) external onlyOwner {
        require(_fee <= MAX_FEE, 'fee too high');
        if (_stable) {
            stableFee = _fee;
        } else {
            volatileFee = _fee;
        }
        emit FeeSet(msg.sender, _stable, _fee);
    }

    function getFee(bool _stable) public view returns(uint256) {
        return _stable ? stableFee : volatileFee;
    }

    function pairCodeHash() external pure returns (bytes32) {
        return keccak256(type(Pair).creationCode);
    }

    function getInitializable() external view returns (address, address, bool) {
        return (_temp0, _temp1, _temp);
    }

    function createPair(address tokenA, address tokenB, bool stable) external returns (address pair) {
        require(tokenA != tokenB, 'IA'); // Pair: IDENTICAL_ADDRESSES
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'ZA'); // Pair: ZERO_ADDRESS
        require(getPair[token0][token1][stable] == address(0), 'PE'); // Pair: PAIR_EXISTS - single check is sufficient
        bytes32 salt = keccak256(abi.encodePacked(token0, token1, stable)); // notice salt includes stable as well, 3 parameters
        (_temp0, _temp1, _temp) = (token0, token1, stable);
        pair = address(new Pair{salt:salt}());
        getPair[token0][token1][stable] = pair;
        getPair[token1][token0][stable] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        isPair[pair] = true;
        emit PairCreated(token0, token1, stable, pair, allPairs.length);
    }
}
