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
        bytes32[] memory priceIds = new bytes32[](2);
        address[] memory assets = new address[](2);
        string[] memory descriptions = new string[](2);

        priceIds[0] = 0xcef5ad3be493afef85e77267cb0c07d048f3d54055409a34782996607e48cf0a; // cmETH/mETH RR
        priceIds[1] = 0xee279eeb2fec830e3f535ad4d6524eb35eb1c6890cb1afc0b64554d08c88727e; // mETH/ETH RR 

        assets[0] = 0xE6829d9a7eE3040e1276Fa75293Bde931859e8fA; // cmETH
        assets[1] = 0xE6829d9a7eE3040e1276Fa75293Bde931859e8fA; // cmETH

        descriptions[0] = "cmETH/mETH RR Oracle";
        descriptions[1] = "mETH/ETH RR Oracle";

        // Call the factory
        PythAdapterFactory(0xb555CD0D4C33Dbbf61214ff02694Ff9e37531ECF).batchDeployPythAdapters(priceIds, assets, descriptions);

        vm.stopBroadcast();
    }
}
