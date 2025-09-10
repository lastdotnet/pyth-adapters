// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {PythAggregatorV3StandardizedEma} from "../src/PythAggregatorV3StandardizedEma.sol";
import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";

contract DeployPythAdapterEma is Script {
    function run() external {
        address pythPriceFeedsContract = 0xe9d69CdD6Fe41e7B621B4A688C5D1a68cB5c8ADc;
        // Get the price feed ids from:
        // https://docs.pyth.network/price-feeds/price-feed-ids
        bytes32 usdxlFeedId = 0xe10593860e9ee1c204e4f9569e877502f098dd1a4d84cc5bad06f23f77dcbfe2;

        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        PythAggregatorV3StandardizedEma usdxlEmaOracle =
            new PythAggregatorV3StandardizedEma(pythPriceFeedsContract, usdxlFeedId, "USDXL/USD EMA Oracle");

        console2.log("USDXL/USD EMA Oracle address: ", address(usdxlEmaOracle));
        console2.log("USDXL/USD EMA Oracle description: ", usdxlEmaOracle.description());
        console2.log("USDXL/USD EMA Oracle price: ", usdxlEmaOracle.latestAnswer());
        console2.log("USDXL/USD EMA Oracle decimals: ", usdxlEmaOracle.decimals());

        vm.stopBroadcast();
    }
}
