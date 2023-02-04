// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "contracts/interfaces/IFlow.sol";

contract Flow is IFlow {
    string public constant name = "Velocimeter";
    string public constant symbol = "FLOW";
    uint8 public constant decimals = 18;
    uint256 public totalSupply = 0;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    bool public initialMinted;
    address public minter;
    address public redemptionReceiver;
    address public merkleClaim;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    constructor() {
        minter = msg.sender;
        _mint(msg.sender, 0);
    }

    // No checks as its meant to be once off to set minting rights to BaseV1 Minter
    function setMinter(address _minter) external {
        require(msg.sender == minter);
        minter = _minter;
    }

    function setRedemptionReceiver(address _receiver) external {
        require(msg.sender == minter);
        redemptionReceiver = _receiver;
    }

    function setMerkleClaim(address _merkleClaim) external {
        require(msg.sender == minter);
        merkleClaim = _merkleClaim;
    }

    // NFTs are minted from this amount as well now
    function initialMint(address _recipient) external {
        require(msg.sender == minter && !initialMinted);
        initialMinted = true;
        _mint(_recipient, 400 * 1e6 * 1e18); //#settings
    }

    function approve(address _spender, uint256 _value) external returns (bool) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function _mint(address _to, uint256 _amount) internal returns (bool) {
        totalSupply += _amount;
        unchecked {
            balanceOf[_to] += _amount;
        }
        emit Transfer(address(0x0), _to, _amount);
        return true;
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _value
    ) internal returns (bool) {
        balanceOf[_from] -= _value;
        unchecked {
            balanceOf[_to] += _value;
        }
        emit Transfer(_from, _to, _value);
        return true;
    }

    function transfer(address _to, uint256 _value) external returns (bool) {
        return _transfer(msg.sender, _to, _value);
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool) {
        uint256 allowed_from = allowance[_from][msg.sender];
        if (allowed_from != type(uint256).max) {
            allowance[_from][msg.sender] -= _value;
        }
        return _transfer(_from, _to, _value);
    }

    function mint(address account, uint256 amount) external returns (bool) {
        require(msg.sender == minter);
        _mint(account, amount);
        return true;
    }

    function claim(address account, uint256 amount) external returns (bool) {
        require(msg.sender == redemptionReceiver || msg.sender == merkleClaim);
        _mint(account, amount);
        return true;
    }
}
