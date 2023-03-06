// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// Scripting tool
import {Script} from "../lib/forge-std/src/Script.sol";

import {FlowConvertor} from "../contracts/FlowConvertor.sol";

contract FlowConvertorDeployment is Script {
    address private constant TEAM_MULTI_SIG = 0x13eeB8EdfF60BbCcB24Ec7Dd5668aa246525Dc51;
    // TODO: Fill the address
    address private constant FLOW = 0x0000000000000000000000000000000000000000;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        FlowConvertor flowConvertor = new FlowConvertor({_v1: 0x2baec546a92ca3469f71b7a091f7df61e5569889, _v2: FLOW});

        flowConvertor.transferOwnership(TEAM_MULTI_SIG);

        IERC20(FLOW).transfer(address(flowConvertor), 50_000_000e18);

        vm.stopBroadcast();
    }
}
