// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {PythAggregatorV3} from "@pythnetwork/pyth-sdk-solidity/PythAggregatorV3.sol";
import {PythAggregatorV3Standardized} from "src/PythAggregatorV3Standardized.sol";
import {console2} from "forge-std/console2.sol";

contract DeployPythUsolAdapter is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Get the address for your ecosystem from:
        // https://docs.pyth.network/price-feeds/contract-addresses/evm
        address pythPriceFeedsContract = 0xe9d69CdD6Fe41e7B621B4A688C5D1a68cB5c8ADc;
        // Get the price feed ids from:
        // https://insights.pyth.network/price-feeds/Crypto.USOL%2FUSD
        bytes32 hypeFeedId = 0x974c7a77dbace44d229be17fc176975e06404b004476aeaff37641818cb0c55a;

        // Deploy an instance of PythAggregatorV3 for every feed.
        PythAggregatorV3Standardized usolAggregator =
            new PythAggregatorV3Standardized(pythPriceFeedsContract, hypeFeedId, "USOL/USD Oracle");

        // Pass the address of the PythAggregatorV3 contract to your chainlink-compatible app.
        console2.log("USOL price: ", usolAggregator.latestAnswer());
        console2.log("USOL decimals: ", usolAggregator.decimals());
        console2.log("USOL description: ", usolAggregator.description());

        vm.stopBroadcast();
    }
}
