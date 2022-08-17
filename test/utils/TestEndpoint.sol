pragma solidity 0.8.13;

import "LayerZero/interfaces/ILayerZeroReceiver.sol";
import "contracts/redeem/RedemptionReceiver.sol";

contract TestEndpoint {
    RedemptionReceiver receiver;
    uint16 public immutable chainId;
    uint64 public nonce;

    constructor(uint16 _chainId) {
        chainId = _chainId;
    }

    function getOutboundNonce(uint16 _dstChainId, address _srcAddress) external view returns (uint64) {
        return 0;
    }

    function send(
        uint16,
        bytes calldata destination,
        bytes calldata payload,
        address payable,
        address,
        bytes calldata
    ) external payable {
        ILayerZeroReceiver(addressFromPackedBytes(destination)).lzReceive(
            chainId,
            abi.encodePacked(msg.sender),
            nonce++,
            payload
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
}
