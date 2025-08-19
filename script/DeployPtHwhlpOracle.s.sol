// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {PtRedemptionOracle} from "../src/oracle/PtRedemptionOracle.sol";
import {PtUsdOracle} from "../src/oracle/PtUsdOracle.sol";
import {PythAggregatorV3Standardized} from "src/PythAggregatorV3Standardized.sol";
import {IEACAggregatorProxy} from "src/oracle/interfaces/IEACAggregatorProxy.sol";
import {console} from "forge-std/console.sol";

contract DeployPtHwhlpOracles is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Get deployment parameters from environment variables
        address pendleOracle = 0x9a9Fa8338dd5E5B2188006f1Cd2Ef26d921650C2;
        address ptHwhlpMarket = 0x905A911E627EcCc7A0Ee3A30bb4f7e98501A1fB1;
        address ptHwhlpToken = 0xfdF1704a7D60Ab07D9889f33951633e7a80E34a3;
        address hwhlpToken = 0x9FD7466f987Fd4C45a5BBDe22ED8aba5BC8D72d1;
        uint256 twapWindow = 15 minutes;
        PythAggregatorV3Standardized usdcUsdOracle = new PythAggregatorV3Standardized(
            0xe9d69CdD6Fe41e7B621B4A688C5D1a68cB5c8ADc,
            0xeaa020c61cc479712813461ce153894a96a6c00b21ed0cfc2798d1f9a9e9c94a,
            "USDC/USD Oracle"
        );

        require(twapWindow <= uint256(type(uint32).max), "TWAP window must be at most 2^32 - 1");

        console.log("Deployment Parameters:");
        console.log("Pendle Oracle:", pendleOracle);
        console.log("PThwHLP Market:", ptHwhlpMarket);
        console.log("PThwHLP Token:", ptHwhlpToken);
        console.log("HWHLP Token:", hwhlpToken);
        console.log("TWAP Window:", twapWindow);
        console.log("USDC/USD Oracle:", address(usdcUsdOracle));

        // Deploy the PThwHLP/hwHLP redemption rate oracle
        console.log("\nDeploying PtHwhlpRedemptionOracle...");
        PtRedemptionOracle redemptionOracle =
            new PtRedemptionOracle(pendleOracle, ptHwhlpMarket, ptHwhlpToken, hwhlpToken, uint32(twapWindow), "PThwHLP/hwHLP Redemption Rate Oracle");
        console.log("PtRedemptionOracle deployed at:", address(redemptionOracle));

        // Test the redemption rate oracle
        try redemptionOracle.latestAnswer() returns (int256 redemptionRate) {
            console.log("Redemption rate (PThwHLP/USDC):", redemptionRate);
        } catch Error(string memory reason) {
            console.log("Failed to get redemption rate:", reason);
        } catch {
            console.log("Failed to get redemption rate: unknown error");
        }

        // Deploy the PThwHLP/USD price oracle
        console.log("\nDeploying PtHwhlpOracle...");
        PtUsdOracle ptHwhlpOracle = new PtUsdOracle(address(redemptionOracle), address(usdcUsdOracle), "PThwHLP/USD Price Oracle");
        console.log("PtHwhlpOracle deployed at:", address(ptHwhlpOracle));

        // Test the PThwHLP/USD oracle
        try ptHwhlpOracle.latestAnswer() returns (int256 hwhlpUsdPrice) {
            console.log("PThwHLP/USD price:", hwhlpUsdPrice);
        } catch Error(string memory reason) {
            console.log("Failed to get PThwHLP/USD price:", reason);
        } catch {
            console.log("Failed to get PThwHLP/USD price: unknown error");
        }

        // Get oracle metadata
        console.log("\nOracle Metadata:");
        console.log("Redemption Oracle Decimals:", redemptionOracle.decimals());
        console.log("PThwHLP/USD Oracle Decimals:", usdcUsdOracle.decimals());
        console.log("Redemption Oracle Description:", redemptionOracle.description());
        console.log("PThwHLP/USD Oracle Description:", usdcUsdOracle.description());

        // Summary
        console.log("\n=== Deployment Summary ===");
        console.log("PtHwhlpRedemptionOracle:", address(redemptionOracle));
        console.log("PtHwhlpOracle:", address(ptHwhlpOracle));
        console.log("USDC/USD Oracle:", address(usdcUsdOracle));
        console.log("==========================");

        vm.stopBroadcast();
    }
}
