// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {PendleUniversalAdapter} from "src/oracle/pendle/PendleUniversalAdapter.sol";

contract DeployPendleUniversalAdapter is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy the PendleUniversalAdapter contract
        new PendleUniversalAdapter(vm.envAddress("PENDLE_ORACLE"));

        vm.stopBroadcast();
    }
}
