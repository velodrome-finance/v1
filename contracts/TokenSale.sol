// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import "contracts/interfaces/IERC20.sol";
import "openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";

contract TokenSale is Ownable, ReentrancyGuard {
    IERC20 public immutable salesToken;
    uint256 public immutable tokensToSell;
    uint256 public immutable wlRate;
    uint256 public immutable publicRate;

    bool public started; // 1st stage: WL sale
    bool public publicRoundStarted; // 2nd stage: public sale
    bool public finished; // 3rd stage: finished and claimable
    
    bytes32 public merkleRoot;

    uint256 public totalTokensSold;
    mapping(address => uint256) public claimableAmounts; // amount of tokens claimable by user
    mapping(address => uint256) public wlCommitments; // amount of ETH committed in WL sale

    constructor(
        IERC20 _salesToken,
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

        salesToken = _salesToken;
        tokensToSell = _tokensToSell;
        wlRate = _wlRate;
        publicRate = _publicRate;
    }

    // owner can set merkle root for WL sale
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    // start WL sale and transfer tokens to this contract
    function start() external onlyOwner {
        require(!started, "Already started");
        started = true;
        _safeTransferFrom(address(salesToken), msg.sender, address(this), tokensToSell);
    }

    // start public sale, can only be called after WL sale is started
    function startPublicRound() external onlyOwner {
        require(started, "Not started yet");
        require(!publicRoundStarted, "Already started");
        publicRoundStarted = true;
    }
    
    function finish() external onlyOwner {
        require(!finished, "Already finished");
        finished = true;

        // transfer remaining tokens back to owner
        uint256 remainingTokens = salesToken.balanceOf(address(this)) - totalTokensSold;
        _safeTransfer(address(salesToken), msg.sender, remainingTokens);

        // transfer ETH to owner
        uint256 remainingETH = address(this).balance;
        (bool success, ) = msg.sender.call{value: remainingETH}("");
        require(success, "Failed to transfer ether");
    }

    // user address + index + capAmount must match merkle proof
    // capAmount is the max amount of ETH user can commit for WL sale
    function commitWhitelist(uint256 index, uint256 capAmount, bytes32[] calldata merkleProof) external payable nonReentrant {
        require(started, "Not started yet");
        require(!finished, "Already finished");
        require(!publicRoundStarted, "Public round already started");

        // Verify the merkle proof
        bytes32 node = keccak256(bytes.concat(keccak256(abi.encode(msg.sender, capAmount))));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), "Invalid proof");
        require(wlCommitments[msg.sender] < capAmount, "Individual cap reached");

        uint256 tokenAmount = msg.value * wlRate;

        require(totalTokensSold + tokenAmount <= tokensToSell, "Global cap reached");

        claimableAmounts[msg.sender] += tokenAmount;
        wlCommitments[msg.sender] += msg.value;
        totalTokensSold += tokenAmount;
    }

    function commitPublic() external payable nonReentrant {
        require(publicRoundStarted, "Not started yet");
        require(!finished, "Already finished");

        uint256 tokenAmount = msg.value * publicRate;
        require(totalTokensSold + tokenAmount <= tokensToSell, "Global cap reached");
        claimableAmounts[msg.sender] += tokenAmount;
        totalTokensSold += tokenAmount;
    }

    function claim() external nonReentrant {
        require(finished, "Not finished yet");
        require(claimableAmounts[msg.sender] > 0, "Nothing to claim");

        uint256 amt = claimableAmounts[msg.sender];
        claimableAmounts[msg.sender] = 0;
        _safeTransfer(address(salesToken), msg.sender, amt);
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

    // View functions

    function getClaimableAmount(address _user) external view returns (uint256) {
        return claimableAmounts[_user];
    }

    function getRemainingTokens() external view returns (uint256) {
        return tokensToSell - totalTokensSold;
    }

    function getWlCommitment(address _user) external view returns (uint256) {
        return wlCommitments[_user];
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
