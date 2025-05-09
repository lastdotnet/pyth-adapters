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
        // https://docs.pyth.net    work/price-feeds/price-feed-ids
        bytes32 lhypeFeedId = 0x9e3cadc2a8a0ebfd765b34d5ee5de77a4add3114672fc0b8d3ad09ac56940069;

        // Deploy an instance of PythAggregatorV3 for every feed.
        PythAggregatorV3 lhypeAggregator = new PythAggregatorV3(pythPriceFeedsContract, lhypeFeedId);

        // Pass the address of the PythAggregatorV3 contract to your chainlink-compatible app.
        console.log("Lhype price: ", lhypeAggregator.latestAnswer());
        console.log("Lhype price decimals: ", lhypeAggregator.decimals());

        vm.stopBroadcast();
    }
}
