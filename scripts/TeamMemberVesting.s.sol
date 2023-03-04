// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// Scripting tool
import {Script} from "../lib/forge-std/src/Script.sol";

import {FlowVestor} from "../contracts/FlowVestor.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract TeamMemberVesting is Script {
    address private constant TEAM_MULTI_SIG = 0x13eeB8EdfF60BbCcB24Ec7Dd5668aa246525Dc51;

    // team member addresses
    address private constant T0RB1K = 0x0b776552c1aef1dc33005dd25acda22493b6615d;
    address private constant MOTTO = 0x78e801136f77805239a7f533521a7a5570f572c8;
    address private constant COOLIE = 0x03b88dacb7c21b54cefecc297d981e5b721a9df1;

    address private constant ADMIN = 0xBC3043983276887f6b6F164Df33646479C9b1653;
    // TODO: Fill the address
    address private constant FLOW = 0x0000000000000000000000000000000000000000;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        FlowVestor flowVestor = new FlowVestor(ADMIN, FLOW);

        IERC20(FLOW).approve(address(flowVestor), 4_500_000e18);
        flowVestor.vestFor(T0RB1K, 2_000_000e18);
        flowVestor.vestFor(MOTTO, 2_000_000e18);
        flowVestor.vestFor(COOLIE, 500_000e18);

        flowVestor.transferOwnership(TEAM_MULTI_SIG);

        IERC20(FLOW).transfer(TEAM_MULTI_SIG, 2_500_000e18);

        vm.stopBroadcast();
    }
}
