// SPDX-License-Identifier: MIT AND AGPL-3.0-or-later
pragma solidity 0.8.13;

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

// Inspired by https://github.com/vetherasset/vader-protocol-v2/blob/main/contracts/tokens/vesting/LinearVesting.sol
/**
 * @dev Implementation of the Linear Vesting
 *
 * The straightforward vesting contract that gradually releases a
 * fixed supply of tokens to multiple vest parties over a 1 year
 * window.
 *
 * The token expects the {begin} hook to be invoked the moment
 * it is supplied with the necessary amount of tokens to vest
 */
contract FlowVestor is Ownable {
    address public revokeTo;
    /* ========== CONSTANTS ========== */

    address internal constant _ZERO_ADDRESS = address(0);

    uint256 internal constant _ONE_YEAR = 365 days;

    /* ========== FLOW ALLOCATION ========== */

    // The FLOW token
    IERC20 public immutable FLOW;

    /* ========== VESTING ========== */

    // Vesting Duration
    uint256 public constant VESTING_DURATION = 1 * _ONE_YEAR;

    /* ========== STRUCTS ========== */

    // Struct of a vesting member, tight-packed to 256-bits
    struct Vester {
        uint192 amount;
        uint64 lastClaim;
        uint128 start;
        uint128 end;
    }

    /* ========== EVENTS ========== */

    event RevokeToUpdated(address oldAddress, address newAddress);
    event VestingCreated(address user, uint256 amount);
    event VestingCancelled(address user, uint256 amount);
    event Vested(address indexed from, uint256 amount);

    /* ========== STATE VARIABLES ========== */

    // The status of each vesting member (Vester)
    mapping(address => Vester) public vest;

    /* ========== CONSTRUCTOR ========== */

    /**
     * @dev Initializes the FLOW token address
     *
     * Additionally, it transfers ownership to the Owner contract that needs to consequently
     * initiate the vesting period via {begin} after it mints the necessary amount to the contract.
     */
    constructor(address _admin, address _FLOW) {
        require(_admin != _ZERO_ADDRESS, "Misconfiguration");
        FLOW = IERC20(_FLOW);
        transferOwnership(_admin);
    }

    /* ========== VIEWS ========== */

    /**
     * @dev Returns the amount a user can claim at a given point in time.
     *
     * Requirements:
     * - the vesting period has started
     */
    function getClaim(address _vester)
        external
        view
        returns (uint256 vestedAmount)
    {
        Vester memory vester = vest[_vester];
        return
            _getClaim(
                vester.amount,
                vester.lastClaim,
                vester.start,
                vester.end
            );
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @dev Allows a user to claim their pending vesting amount of the vested claim
     *
     * Emits a {Vested} event indicating the user who claimed their vested tokens
     * as well as the amount that was vested.
     *
     * Requirements:
     *
     * - the vesting period has started
     * - the caller must have a non-zero vested amount
     */
    function claim() external returns (uint256 vestedAmount) {
        Vester memory vester = vest[msg.sender];

        require(vester.start != 0, "Not Started");

        require(vester.start < block.timestamp, "Not Started Yet");

        vestedAmount = _getClaim(
            vester.amount,
            vester.lastClaim,
            vester.start,
            vester.end
        );

        require(vestedAmount != 0, "Nothing to claim");

        vester.amount -= uint192(vestedAmount);
        vester.lastClaim = uint64(block.timestamp);

        vest[msg.sender] = vester;

        emit Vested(msg.sender, vestedAmount);

        FLOW.transfer(msg.sender, vestedAmount);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
     * @dev Adds a new vesting schedule to the contract.
     *
     * Requirements:
     * - Only {owner} can call.
     */
    function vestFor(address user, uint256 amount) external onlyOwner {
        require(amount <= type(uint192).max, "Amount Overflows uint192");
        require(vest[user].amount == 0, "Already a vester");
        vest[user] = Vester(
            uint192(amount),
            0,
            uint128(block.timestamp),
            uint128(block.timestamp + VESTING_DURATION)
        );
        FLOW.transferFrom(msg.sender, address(this), amount);

        emit VestingCreated(user, amount);
    }

    function cancelVest(address user) external onlyOwner {
        require(revokeTo != address(0), "0 revoke to address");
        uint256 amount = vest[user].amount;
        require(amount > 0, "Not a vester");
        require(
            FLOW.balanceOf(address(this)) >= amount,
            "Insufficient FLOW balance"
        );
        delete vest[user];
        FLOW.transfer(revokeTo, amount);

        emit VestingCancelled(user, amount);
    }

    function setRevokeTo(address _revokeTo) external onlyOwner {
        require(_revokeTo != address(0), "0 address");
        emit RevokeToUpdated(revokeTo, _revokeTo);
        revokeTo = _revokeTo;
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _getClaim(
        uint256 amount,
        uint256 lastClaim,
        uint256 _start,
        uint256 _end
    ) private view returns (uint256) {
        if (block.timestamp >= _end) return amount;
        if (lastClaim == 0) lastClaim = _start;

        return (amount * (block.timestamp - lastClaim)) / (_end - lastClaim);
    }
}
