// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import "contracts/interfaces/IERC20.sol";
import "contracts/interfaces/IVotingEscrow.sol";

import "openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";

contract TokenSale is Ownable, ReentrancyGuard {
    // Status of the sale
    // NOT_STARTED: initial stage, WL sale not started yet
    // WHITELIST_ROUND: WL sale started, only whitelisted users can participate
    // PUBLIC_ROUND: public sale started, anyone can participate
    // FINISHED_UNCLAIMABLE: sale finished, tokens can't be claimed yet
    // FINISHED_CLAIMABLE: sale finished, tokens can be claimed
    enum Status { NOT_STARTED, WHITELIST_ROUND, PUBLIC_ROUND, FINISHED_UNCLAIMABLE, FINISHED_CLAIMABLE }

    IERC20 public immutable salesToken;
    IVotingEscrow public immutable ve;
    uint256 public immutable tokensToSell;
    uint256 public immutable wlRate;
    uint256 public immutable publicRate;
    uint256 public immutable maxBonusPercentage;

    Status public status;
    
    bytes32 public merkleRoot;

    // Total tokens sold, not including bonus
    // After the sale concludes, `tokensToSell - totalTokensSold` amount of tokens will be burned if there are any left
    uint256 public totalTokensSold;

    // Tokens reserved in the contract for sales + max bonus
    // Only unreserved tokens can be withdrawn by team after sale ends
    uint256 public reservedTokens;

    mapping(address => uint256) public claimableAmounts; // amount of tokens claimable by user
    mapping(address => uint256) public wlCommitments; // amount of ETH committed in WL sale

    uint internal constant MAX_LOCK_WEEKS = 52; // max lock is 1 year
    uint internal constant MIN_LOCK_WEEKS = 4;

    // mapping from lock time (in months) to bonus percentage
    // we treat 1 month = 4 weeks for simplicity
    mapping(uint => uint) internal bonusPercentages; 

    constructor(
        IERC20 _salesToken,
        IVotingEscrow _ve,
        uint256 _wlRate, // whitelist sale ETH to token conversion rate
        uint256 _publicRate, // public sale ETH to token conversion rate
        uint256 _tokensToSell
    ) {
        require(
            _wlRate >= _publicRate,
            "WL price must not be higher than public"
        );

        // token must be 18 decimals, otherwise we'll have problems with ETH conversion rate
        require(_salesToken.decimals() == 18, "Token must be 18 decimals");

        require(_ve.token() == address(_salesToken), "ve token address mismatch");

        salesToken = _salesToken;
        ve = _ve;
        tokensToSell = _tokensToSell;
        wlRate = _wlRate;
        publicRate = _publicRate;
        status = Status.NOT_STARTED;
        bonusPercentages[1] = 6; // 1 mo lock = 6% bonus in veVS
        bonusPercentages[2] = 12; // 2 mo lock = 12% bonus
        bonusPercentages[4] = 18; // 4 mo lock = 18% bonus
        bonusPercentages[8] = 24; // 8 mo lock = 24% bonus
        bonusPercentages[12] = 30; // 12 mo lock = 30% bonus
        maxBonusPercentage = 30; // 30% max bonus
        _salesToken.approve(address(_ve), type(uint).max);
    }

    // owner can set merkle root for WL sale
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    // ------- Sales Status Management -------

    // start WL sale and transfer tokens to this contract
    function start() external onlyOwner {
        require(status == Status.NOT_STARTED, "Invalid status");
        status = Status.WHITELIST_ROUND;
        _safeTransferFrom(address(salesToken), msg.sender, address(this), tokensToSell * (100 + maxBonusPercentage) / 100);
    }

    // start public sale, can only be called after WL sale is started
    function startPublicRound() external onlyOwner {
        require(status == Status.WHITELIST_ROUND, "Invalid status");
        status = Status.PUBLIC_ROUND;
    }
    
    // finish sale, can only be called after public sale is started
    // ETH will be transferred to owner
    function finish() external onlyOwner {
        require(status == Status.PUBLIC_ROUND, "Invalid status");
        status = Status.FINISHED_UNCLAIMABLE;

        // transfer ETH to owner
        uint256 remainingETH = address(this).balance;
        (bool success, ) = msg.sender.call{value: remainingETH}("");
        require(success, "Failed to transfer ether");
    }

    // enable claiming, can only be called after sale is finished
    function enableClaim() external onlyOwner {
        require(status == Status.FINISHED_UNCLAIMABLE, "Invalid status");
        status = Status.FINISHED_CLAIMABLE;
    }
    
    // ------- user interaction -------

    // user address + capAmount must match merkle proof
    // capAmount is the max amount of ETH user can commit for WL sale
    function commitWhitelist(uint256 capAmount, bytes32[] calldata merkleProof) external payable nonReentrant {
        require(msg.value > 0, "No ETH sent");
        require(capAmount > 0, "Cap amount must be > 0");
        require(status == Status.WHITELIST_ROUND, "Not whitelist round");

        // Verify the merkle proof
        bytes32 node = keccak256(bytes.concat(keccak256(abi.encode(msg.sender, capAmount))));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), "Invalid proof");
        require(wlCommitments[msg.sender] + msg.value <= capAmount, "Individual cap reached");

        uint256 tokenAmount = msg.value * wlRate;

        require(totalTokensSold + tokenAmount <= tokensToSell, "Global cap reached");

        claimableAmounts[msg.sender] += tokenAmount;
        wlCommitments[msg.sender] += msg.value;
        totalTokensSold += tokenAmount;
        reservedTokens += ((tokenAmount * (100 + maxBonusPercentage)) / 100);
    }

    function commitPublic() external payable nonReentrant {
        require(status == Status.PUBLIC_ROUND, "Not public round");

        uint256 tokenAmount = msg.value * publicRate;
        require(totalTokensSold + tokenAmount <= tokensToSell, "Global cap reached");
        claimableAmounts[msg.sender] += tokenAmount;
        totalTokensSold += tokenAmount;
        reservedTokens += ((tokenAmount * (100 + maxBonusPercentage)) / 100);
    }

    function claim() external nonReentrant {
        require(status == Status.FINISHED_CLAIMABLE, "Cannot claim yet");
        require(claimableAmounts[msg.sender] > 0, "Nothing to claim");

        uint256 amt = claimableAmounts[msg.sender];
        claimableAmounts[msg.sender] = 0;
        _safeTransfer(address(salesToken), msg.sender, amt);

        // decrease the amount of reserved tokens
        reservedTokens -= (amt + amt * maxBonusPercentage / 100);
    }

    function claimAndLock(uint lockMonths) external nonReentrant {
        require(status == Status.FINISHED_CLAIMABLE, "Cannot claim yet");
        require(claimableAmounts[msg.sender] > 0, "Nothing to claim");
        require(bonusPercentages[lockMonths] > 0, "Must lock 1/2/4/8/12 months");

        // convert lock duration to seconds
        uint256 lockDurationSeconds = lockMonths * 4 weeks;

        uint256 amt = claimableAmounts[msg.sender];
        claimableAmounts[msg.sender] = 0;
        ve.create_lock_for(amt, lockDurationSeconds, msg.sender);

        // transfer bonus tokens
        uint256 bonus = amt * bonusPercentages[lockMonths] / 100;
        _safeTransfer(address(salesToken), msg.sender, bonus);

        // decrease the amount of reserved tokens
        reservedTokens -= (amt + amt * maxBonusPercentage / 100);
    }

    receive() external payable {}

    function emergencyWithdrawETH() external onlyOwner {
        uint256 remainingETH = address(this).balance;
        msg.sender.call{value: remainingETH}("");
    }

    function emergencyWithdrawTokens() external onlyOwner {
        uint256 allTokens = salesToken.balanceOf(address(this));
        _safeTransfer(address(salesToken), msg.sender, allTokens);
    }

    // use this to withdraw remaining tokens from the contract after sale is finished and claimable (final stage)
    function withdrawRemainingTokens() external onlyOwner {
        require(status == Status.FINISHED_CLAIMABLE, "Cannot withdraw remaining tokens yet");
        _safeTransfer(address(salesToken), msg.sender, getRemainingTokens());
    }

    // View functions

    function getClaimableAmount(address _user) public view returns (uint256) {
        return claimableAmounts[_user];
    }

    function getWlCommitment(address _user) public view returns (uint256) {
        return wlCommitments[_user];
    }

    function getRemainingTokens() public view returns (uint256) {
        return salesToken.balanceOf(address(this)) - reservedTokens;
    }

    function getStatus() public view returns (uint) {
        return uint(status);
    }
    
    // Helper functions

    function _safeTransfer(address token, address to, uint256 value) internal {
        require(token.code.length > 0);
        (bool success, bytes memory data) =
        token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function _safeTransferFrom(address token, address from, address to, uint256 value) internal {
        require(token.code.length > 0);
        (bool success, bytes memory data) =
        token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }
}
