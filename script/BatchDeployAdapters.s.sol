// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "src/PythAdapterFactory.sol";
import {console} from "forge-std/console.sol";

contract BatchDeployAdapters is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Optional: Deploy some initial adapters
        bytes32[] memory priceIds = new bytes32[](1);
        address[] memory assets = new address[](1);
        string[] memory descriptions = new string[](1);

        priceIds[0] = 0x58cd29ef0e714c5affc44f269b2c1899a52da4169d7acc147b9da692e6953608; // FARTCOIN/USD

        assets[0] = 0x3B4575E689DEd21CAAD31d64C4df1f10F3B2CedF; // UFART

        descriptions[0] = "FARTCOIN/USD Oracle";

        // Call the factory
        PythAdapterFactory(0xE651d406175C19E7CbBdD28B3EdC0568A2f68F7C).batchDeployPythAdapters(
            priceIds, assets, descriptions
        );

        PythAggregatorV3(0xf44F2ACB8d25be55C9F0EF7C7bf1AB840a7DD745).priceId();

        PythAggregatorV3(0xf44F2ACB8d25be55C9F0EF7C7bf1AB840a7DD745).latestAnswer();

        vm.stopBroadcast();
    }
}
