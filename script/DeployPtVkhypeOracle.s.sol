// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {PtRedemptionOracle} from "../src/oracle/PtRedemptionOracle.sol";
import {PtUsdOracle} from "../src/oracle/PtUsdOracle.sol";
import {console} from "forge-std/console.sol";

contract DeployPtVkhypeOracle is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Get deployment parameters from environment variables
        address pendleOracle = 0x9a9Fa8338dd5E5B2188006f1Cd2Ef26d921650C2;
        address ptvkhypeMarket = 0x61E4A41853550dc09DC296088AC83d770CD45C5a;
        address ptvkhypeToken = 0x31CC92a2f8c02b8F9f427c48f12E21a848e69847;
        address hypeToken = 0x5555555555555555555555555555555555555555;
        uint32 twapWindow = 15 minutes;
        address hypeUsdOracle = 0x1d0E4EA616A749c1620118F7d97c111e8ec36E8b;

        console.log("Deployment Parameters:");
        console.log("Pendle Oracle:", pendleOracle);
        console.log("PTvKHYPE Market:", ptvkhypeMarket);
        console.log("PTvKHYPE Token:", ptvkhypeToken);
        console.log("HYPE Token:", hypeToken);
        console.log("TWAP Window:", twapWindow);
        console.log("HYPE/USD Oracle:", hypeUsdOracle);

        // Deploy the PTvKHYPE/vKHYPE redemption rate oracle
        console.log("\nDeploying PtVkhypeRedemptionOracle...");
        PtRedemptionOracle redemptionOracle = new PtRedemptionOracle(
            pendleOracle, ptvkhypeMarket, ptvkhypeToken, hypeToken, twapWindow, "PTvKHYPE/WHYPE Redemption Rate Oracle"
        );
        console.log("PtVkhypeRedemptionOracle deployed at:", address(redemptionOracle));

        // Test the redemption rate oracle
        try redemptionOracle.latestAnswer() returns (int256 redemptionRate) {
            console.log("Redemption rate (PTvKHYPE/WHYPE):", redemptionRate);
        } catch Error(string memory reason) {
            console.log("Failed to get redemption rate:", reason);
        } catch {
            console.log("Failed to get redemption rate: unknown error");
        }

        // Deploy the PTvKHYPE/USD price oracle
        console.log("\nDeploying PtVkhypeOracle...");
        PtUsdOracle ptvkhypeUsdOracle =
            new PtUsdOracle(address(redemptionOracle), hypeUsdOracle, "PTvKHYPE/USD Price Oracle");
        console.log("PtVkhypeOracle deployed at:", address(ptvkhypeUsdOracle));

        // Test the PTvKHYPE/USD oracle
        try ptvkhypeUsdOracle.latestAnswer() returns (int256 ptvkhypeUsdPrice) {
            console.log("PTvKHYPE/USD price:", ptvkhypeUsdPrice);
        } catch Error(string memory reason) {
            console.log("Failed to get PTvKHYPE/USD price:", reason);
        } catch {
            console.log("Failed to get PTvKHYPE/USD price: unknown error");
        }

        // Get oracle metadata
        console.log("\nOracle Metadata:");
        console.log("Redemption Oracle Decimals:", redemptionOracle.decimals());
        console.log("PTvKHYPE/USD Oracle Decimals:", ptvkhypeUsdOracle.decimals());
        console.log("Redemption Oracle Description:", redemptionOracle.description());
        console.log("PTvKHYPE/USD Oracle Description:", ptvkhypeUsdOracle.description());

        // Summary
        console.log("\n=== Deployment Summary ===");
        console.log("PtVkhypeRedemptionOracle:", address(redemptionOracle));
        console.log("PtVkhypeOracle:", address(ptvkhypeUsdOracle));
        console.log("HYPE/USD Oracle:", hypeUsdOracle);
        console.log("==========================");

        vm.stopBroadcast();
    }
}
