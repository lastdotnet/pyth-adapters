// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {KhypeOracle} from "src/oracle/KhypeOracle.sol";

contract DeployKhypeOracle is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy the KhypeOracle contract
        KhypeOracle khypeOracle = new KhypeOracle();

        console.log("KhypeOracle deployed at:", address(khypeOracle));

        vm.stopBroadcast();
    }
}