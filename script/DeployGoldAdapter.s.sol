// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {PythAggregatorV3Standardized} from "src/PythAggregatorV3Standardized.sol";

contract DeployGoldAdapter is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Set the address of the Pyth price feeds contract for your network.
        // Example: Ethereum mainnet: 0xff1a0f4744e8582DF1Ac3A9FdC6C1B2D0B5e981C
        address pythPriceFeedsContract = 0xe9d69CdD6Fe41e7B621B4A688C5D1a68cB5c8ADc;

        // Set the priceId for Gold/USD from Pyth.
        // You must replace this with the correct priceId for Gold/USD from the Pyth documentation:
        // https://insights.pyth.network/price-feeds
        bytes32 goldPriceId = 0x765d2ba906dbc32ca17cc11f5310a89e9ee1f6420508c63861f2f8ba4ee34bb2;

        // Set a description for the adapter
        string memory description = "XAUt0/USD Oracle";

        // Deploy the standardized adapter
        new PythAggregatorV3Standardized(pythPriceFeedsContract, goldPriceId, description);

        vm.stopBroadcast();
    }
}
