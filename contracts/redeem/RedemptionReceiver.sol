// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "LayerZero/interfaces/ILayerZeroEndpoint.sol";
import "LayerZero/interfaces/ILayerZeroReceiver.sol";
import "contracts/interfaces/IERC20.sol";
import "contracts/interfaces/IFlow.sol";

/// @notice Part 2 of 2 in the WeVE (FTM) -> USDC + FLOW (OP) redemption process
/// This contract is responsible for receiving the LZ message and distributing USDC + FLOW
contract RedemptionReceiver is ILayerZeroReceiver {
    IERC20 public immutable USDC;
    IFlow public immutable FLOW;

    uint16 public immutable fantomChainId; // 12 for FTM, 10012 for FTM testnet
    address public immutable endpoint;

    address public team;
    uint256 public immutable deployed;

    address public fantomSender;
    uint256 public constant ELIGIBLE_WEVE = 375112540 * 1e18;
    uint256 public redeemedWEVE;
    uint256 public redeemableUSDC;
    uint256 public redeemableFLOW;
    uint256 public leftoverFLOW;

    constructor(
        address _usdc,
        address _flow,
        uint16 _fantomChainId,
        address _endpoint
    ) {
        require(_fantomChainId == 12 || _fantomChainId == 10012, "CHAIN_ID_NOT_FTM");

        USDC = IERC20(_usdc);
        FLOW = IFlow(_flow);

        fantomChainId = _fantomChainId;
        endpoint = _endpoint;

        team = msg.sender;
        deployed = block.timestamp;
    }

    modifier onlyTeam() {
        require(msg.sender == team, "ONLY_TEAM");
        _;
    }

    event Initialized(address fantomSender, uint256 redeemableUSDC, uint256 redeemableFLOW);

    function initializeReceiverWith(
        address _fantomSender,
        uint256 _redeemableUSDC,
        uint256 _redeemableFLOW
    ) external onlyTeam {
        require(fantomSender == address(0), "ALREADY_INITIALIZED");
        require(
            USDC.transferFrom(msg.sender, address(this), _redeemableUSDC),
            "USDC_TRANSFER_FAILED"
        );

        fantomSender = _fantomSender;
        redeemableUSDC = _redeemableUSDC;
        redeemableFLOW = _redeemableFLOW;
        leftoverFLOW = _redeemableFLOW;

        emit Initialized(fantomSender, redeemableUSDC, redeemableFLOW);
    }

    function setTeam(address _team) external onlyTeam {
        team = _team;
    }

    function previewRedeem(uint256 amountWEVE)
        public
        view
        returns (uint256 shareOfUSDC, uint256 shareOfFLOW)
    {
        // pro rata USDC
        shareOfUSDC = (amountWEVE * redeemableUSDC) / ELIGIBLE_WEVE;
        // pro rata FLOW
        shareOfFLOW = (amountWEVE * redeemableFLOW) / ELIGIBLE_WEVE;
    }

    function lzReceive(
        uint16 srcChainId,
        bytes memory srcAddress,
        uint64,
        bytes memory payload
    ) external override {
        require(fantomSender != address(0), "NOT_INITIALIZED");
        require(
            msg.sender == endpoint &&
                srcChainId == fantomChainId &&
                addressFromPackedBytes(srcAddress) == fantomSender,
            "UNAUTHORIZED_CALLER"
        );

        (address redemptionAddress, uint256 amountWEVE) = abi.decode(
            payload,
            (address, uint256)
        );

        require(
            (redeemedWEVE += amountWEVE) <= ELIGIBLE_WEVE,
            "cannot redeem more than eligible"
        );
        (uint256 shareOfUSDC, uint256 shareOfFLOW) = previewRedeem(amountWEVE);

        require(
            USDC.transfer(redemptionAddress, shareOfUSDC),
            "USDC_TRANSFER_FAILED"
        );

        leftoverFLOW -= shareOfFLOW; // this will revert if underflows
        require(
            FLOW.claim(redemptionAddress, shareOfFLOW),
            "CLAIM_FAILED"
        );
    }

    function addressFromPackedBytes(bytes memory toAddressBytes)
        public
        pure
        returns (address toAddress)
    {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            toAddress := mload(add(toAddressBytes, 20))
        }
    }

    function claimLeftovers() external onlyTeam {
        require(block.timestamp >= deployed + 30 days, "LEFTOVERS_NOT_CLAIMABLE");
        require(
            USDC.transfer(msg.sender, USDC.balanceOf(address(this))),
            "USDC_TRANSFER_FAILED"
        );
    }
}
