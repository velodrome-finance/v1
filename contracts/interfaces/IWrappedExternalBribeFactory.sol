pragma solidity 0.8.13;

interface IWrappedExternalBribeFactory {
    function createBribe(address) external returns (address);
}
