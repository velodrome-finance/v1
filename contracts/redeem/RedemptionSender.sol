// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "LayerZero/interfaces/ILayerZeroEndpoint.sol";
import "contracts/interfaces/IERC20.sol";

/// @notice Part 1 of 2 in the WeVE (FTM) -> USDC + VELO (OP) redemption process
/// This contract is responsible for burning WeVE and sending the LZ message
contract RedemptionSender {
    address public immutable weve;
    uint256 public constant ELIGIBLE_WEVE = 375112540 * 1e18;
    uint256 public redeemedWEVE;
    uint16 public immutable optimismChainId; // 11 for OP, 10011 for OP Kovan
    address public immutable endpoint;
    address public immutable optimismReceiver;

    event SubmittedClaim(uint256 amount, uint64 indexed lzeNonce);

    constructor(
        address _weve,
        uint16 _optimismChainId,
        address _endpoint,
        address _optimismReceiver
    ) {
        require(_optimismChainId == 11 || _optimismChainId == 10011, "CHAIN_ID_NOT_OP");
        weve = _weve;
        optimismChainId = _optimismChainId;
        endpoint = _endpoint;
        optimismReceiver = _optimismReceiver;
    }

    function estimateLayerZeroFee() public view returns (uint256 ftm, uint256 lzo) {
        (ftm, lzo) = ILayerZeroEndpoint(endpoint).estimateFees(
            optimismChainId,
            address(this),
            abi.encode(msg.sender, 42690),
            false,
            bytes("")
        );
    }

    function redeemWEVE(
        uint256 amount,
        address zroPaymentAddress,
        bytes memory zroTransactionParams
    ) public payable {
        require(amount != 0, "AMOUNT_ZERO");
        require(
            (redeemedWEVE += amount) <= ELIGIBLE_WEVE,
            "cannot redeem more than eligible"
        );
        require(
            IERC20(weve).transferFrom(
                msg.sender,
                0x000000000000000000000000000000000000dEaD,
                amount
            ),
            "WEVE: TRANSFER_FAILED"
        );

        ILayerZeroEndpoint(endpoint).send{value: msg.value}(
            optimismChainId,
            abi.encodePacked(optimismReceiver),
            abi.encode(msg.sender, amount),
            payable(msg.sender),
            zroPaymentAddress,
            zroTransactionParams
        );

        uint64 nonce = ILayerZeroEndpoint(endpoint).getOutboundNonce(
            optimismChainId,
            address(this)
        );

        emit SubmittedClaim(amount, nonce);
    }
}
