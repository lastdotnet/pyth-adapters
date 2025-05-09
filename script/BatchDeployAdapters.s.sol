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

        priceIds[0] = 0x4279e31cc369bbcc2faf022b382b080e32a8e689ff20fbc530d2a603eb6cd98b; // feUSD

        assets[0] = 0x0000000000000000000000000000000000000000;

        descriptions[0] = "USDT0/USD Oracle";

        // Call the factory
        PythAdapterFactory(pythPriceFeedsContract, assets, priceIds, descriptions);

        vm.stopBroadcast();
    }
}
