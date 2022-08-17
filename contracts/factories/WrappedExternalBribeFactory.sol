// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {WrappedExternalBribe} from 'contracts/WrappedExternalBribe.sol';

contract WrappedExternalBribeFactory {
    address public immutable voter;
    mapping(address => address) public oldBribeToNew;
    address public last_bribe;

    constructor(address _voter) {
        voter = _voter;
    }

    function createBribe(address existing_bribe) external returns (address) {
        require(
            oldBribeToNew[existing_bribe] == address(0),
            "Wrapped bribe already created"
        );
        last_bribe = address(new WrappedExternalBribe(voter, existing_bribe));
        oldBribeToNew[existing_bribe] = last_bribe;
        return last_bribe;
    }
}
