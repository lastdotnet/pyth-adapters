// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {PythAggregatorV3} from "@pythnetwork/pyth-sdk-solidity/PythAggregatorV3.sol";
import {console} from "forge-std/console.sol";

contract PythAggregatorV3Deployment is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Get the address for your ecosystem from:
        // https://docs.pyth.network/price-feeds/contract-addresses/evm
        address pythPriceFeedsContract = 0xe9d69CdD6Fe41e7B621B4A688C5D1a68cB5c8ADc;
        // Get the price feed ids from:
        // https://docs.pyth.net/developers/price-feed-ids
        bytes32 ethFeedId = 0xff61491a931112ddf1bd8147cd1b641375f79f5825126d665480874634fd0ace;

        // Deploy an instance of PythAggregatorV3 for every feed.
        PythAggregatorV3 ethAggregator = new PythAggregatorV3(pythPriceFeedsContract, ethFeedId);

        // Pass the address of the PythAggregatorV3 contract to your chainlink-compatible app.
        console.log("Ueth price: ", ethAggregator.latestAnswer());
        console.log("Ueth price decimals: ", ethAggregator.decimals());

        vm.stopBroadcast();
    }
}
