pragma solidity 0.8.13;

import {WETH as WETHToken} from "solmate/tokens/WETH.sol";

contract TestWETH is WETHToken {
    function mint(address to, uint256 value) public virtual {
        _mint(to, value);
    }

    function burn(address from, uint256 value) public virtual {
        _burn(from, value);
    }
}
