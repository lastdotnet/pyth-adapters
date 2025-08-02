// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {OracleMonitor} from "../src/OracleMonitor.sol";
import {console} from "forge-std/console.sol";

contract DeployOracleMonitor is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Aave v3 PoolAddressesProvider addresses
        address aaveAddressesProvider = vm.envAddress("AAVE_ADDRESSES_PROVIDER");

        // Fraxlend registry address
        address fraxlendRegistry = vm.envAddress("FRAXLEND_REGISTRY");

        // Deploy the OracleMonitor
        OracleMonitor monitor = new OracleMonitor(aaveAddressesProvider, fraxlendRegistry);
        console.log("OracleMonitor deployed at:", address(monitor));
        console.log("Aave Addresses Provider:", aaveAddressesProvider);
        console.log("Fraxlend Registry:", fraxlendRegistry);

        // Get initial status report
        OracleMonitor.OracleStatus[] memory statuses = monitor.getAssetStatuses();
        console.log("Total assets monitored:", statuses.length);

        // Log some sample statuses
        uint256 maxToShow = statuses.length > 5 ? 5 : statuses.length;
        for (uint256 i = 0; i < maxToShow; i++) {
            console.log("Asset", i, ":", statuses[i].asset);
            console.log("  Source:", statuses[i].source);
            console.log("  Status:", statuses[i].status);
            console.log("  Price:", statuses[i].latestPrice);
        }

        vm.stopBroadcast();
    }
}
