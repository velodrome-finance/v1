// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "LayerZero/interfaces/ILayerZeroEndpoint.sol";
import "LayerZero/interfaces/ILayerZeroReceiver.sol";
import "contracts/interfaces/IERC20.sol";
import "contracts/interfaces/IVelo.sol";

/// @notice Part 2 of 2 in the WeVE (FTM) -> USDC + VELO (OP) redemption process
/// This contract is responsible for receiving the LZ message and distributing USDC + VELO
contract RedemptionReceiver is ILayerZeroReceiver {
    IERC20 public immutable USDC;
    IVelo public immutable VELO;

    uint16 public immutable fantomChainId; // 12 for FTM, 10012 for FTM testnet
    address public immutable endpoint;

    address public team;
    uint256 public immutable deployed;

    address public fantomSender;
    uint256 public constant ELIGIBLE_WEVE = 375112540 * 1e18;
    uint256 public redeemedWEVE;
    uint256 public redeemableUSDC;
    uint256 public redeemableVELO;
    uint256 public leftoverVELO;

    constructor(
        address _usdc,
        address _velo,
        uint16 _fantomChainId,
        address _endpoint
    ) {
        require(_fantomChainId == 12 || _fantomChainId == 10012, "CHAIN_ID_NOT_FTM");

        USDC = IERC20(_usdc);
        VELO = IVelo(_velo);

        fantomChainId = _fantomChainId;
        endpoint = _endpoint;

        team = msg.sender;
        deployed = block.timestamp;
    }

    modifier onlyTeam() {
        require(msg.sender == team, "ONLY_TEAM");
        _;
    }

    event Initialized(address fantomSender, uint256 redeemableUSDC, uint256 redeemableVELO);

    function initializeReceiverWith(
        address _fantomSender,
        uint256 _redeemableUSDC,
        uint256 _redeemableVELO
    ) external onlyTeam {
        require(fantomSender == address(0), "ALREADY_INITIALIZED");
        require(
            USDC.transferFrom(msg.sender, address(this), _redeemableUSDC),
            "USDC_TRANSFER_FAILED"
        );

        fantomSender = _fantomSender;
        redeemableUSDC = _redeemableUSDC;
        redeemableVELO = _redeemableVELO;
        leftoverVELO = _redeemableVELO;

        emit Initialized(fantomSender, redeemableUSDC, redeemableVELO);
    }

    function setTeam(address _team) external onlyTeam {
        team = _team;
    }

    function previewRedeem(uint256 amountWEVE)
        public
        view
        returns (uint256 shareOfUSDC, uint256 shareOfVELO)
    {
        // pro rata USDC
        shareOfUSDC = (amountWEVE * redeemableUSDC) / ELIGIBLE_WEVE;
        // pro rata VELO
        shareOfVELO = (amountWEVE * redeemableVELO) / ELIGIBLE_WEVE;
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
        (uint256 shareOfUSDC, uint256 shareOfVELO) = previewRedeem(amountWEVE);

        require(
            USDC.transfer(redemptionAddress, shareOfUSDC),
            "USDC_TRANSFER_FAILED"
        );

        leftoverVELO -= shareOfVELO; // this will revert if underflows
        require(
            VELO.claim(redemptionAddress, shareOfVELO),
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
