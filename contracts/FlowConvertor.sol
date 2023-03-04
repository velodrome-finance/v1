pragma solidity 0.8.13;

import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

/**
 * @dev This contract allow users to convert one token to another.
 * It requires both tokens to have valid contract addresses.
 * It requires that it is filled up first with liquid v2 tokens., they dont need to be exact.
 * Any tokens that get sent here accidently can be sent back out, except v1 token.
 */
contract FlowConvertor is Ownable {
    address public immutable v1;
    address public immutable v2;

    constructor(address _v1, address _v2) {
        v1 = _v1;
        v2 = _v2;
    }

    /**
     * @dev Transfers ERC20 v1 from user to contract, and Transfer ERC20 v2 to user, 1 to 1.
     */
    function redeem(uint256 amount) public {
        require(amount > 0, "you dont have and v1 tokens");
        SafeERC20.safeTransferFrom(
            IERC20(v1),
            _msgSender(),
            address(this),
            amount
        );
        SafeERC20.safeTransferFrom(
            IERC20(v2),
            address(this),
            _msgSender(),
            amount
        );
    }

    /**
     * @dev Transfers ERC20 v1 from user to contract, and Transfer ERC20 v2 to an address specified, 1 to 1.
     */
    function redeemTo(address _to, uint256 amount) public {
        require(amount > 0, "you dont have and v1 tokens");
        SafeERC20.safeTransferFrom(
            IERC20(v1),
            _msgSender(),
            address(this),
            amount
        );
        SafeERC20.safeTransferFrom(IERC20(v2), address(this), _to, amount);
    }

    /**
     * @dev Allows owner to clean out the contract of ANY tokens including v2, but not v1
     */
    function inCaseTokensGetStuck(
        address _token,
        address _to,
        uint256 _amount
    ) public onlyOwner {
        require(_token != address(v1), "these tkns are essentially burnt");
        SafeERC20.safeTransfer(IERC20(_token), _to, _amount);
    }

    /**
     * @dev Allows owner sweep out all the remaining v2 tokens.
     */
    function sweepV2(address _to) public onlyOwner {
        uint256 _surplus = IERC20(v2).balanceOf(address(this));
        SafeERC20.safeTransfer(IERC20(v2), _to, _surplus);
    }
}
