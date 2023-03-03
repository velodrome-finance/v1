pragma solidity 0.8.13;

interface IBribeFactory {
    function createExternalBribe(address[] memory) external returns (address);
}
