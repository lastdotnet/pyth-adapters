// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {PtRedemptionOracle} from "../src/oracle/PtRedemptionOracle.sol";
import {PtUsdOracle} from "../src/oracle/PtUsdOracle.sol";
import {console} from "forge-std/console.sol";

contract DeployPTKhypeOracleFixed is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Get deployment parameters from environment variables
        address pendleOracle = 0x9a9Fa8338dd5E5B2188006f1Cd2Ef26d921650C2;
        address ptkhypeMarket = 0x8867d2b7aDb8609c51810237EcC9A25A2F601B97;
        address ptkhypeToken = 0x311dB0FDe558689550c68355783c95eFDfe25329;
        address hypeToken = 0x5555555555555555555555555555555555555555;
        uint32 twapWindow = 15 minutes;
        address hypeUsdOracle = 0x1d0E4EA616A749c1620118F7d97c111e8ec36E8b;

        console.log("Deployment Parameters:");
        console.log("Pendle Oracle:", pendleOracle);
        console.log("PTKHYPE Market:", ptkhypeMarket);
        console.log("PTKHYPE Token:", ptkhypeToken);
        console.log("HYPE Token:", hypeToken);
        console.log("TWAP Window:", twapWindow);
        console.log("HYPE/USD Oracle:", hypeUsdOracle);

        // Deploy the PTKHYPE/KHYPE redemption rate oracle
        console.log("\nDeploying PtKhypeRedemptionOracle...");
        PtRedemptionOracle redemptionOracle = new PtRedemptionOracle(
            pendleOracle, ptkhypeMarket, ptkhypeToken, hypeToken, twapWindow, "PTKHYPE/HYPE Redemption Rate Oracle"
        );
        console.log("PtKhypeRedemptionOracle deployed at:", address(redemptionOracle));

        // Test the redemption rate oracle
        try redemptionOracle.latestAnswer() returns (int256 redemptionRate) {
            console.log("Redemption rate (PTKHYPE/HYPE):", redemptionRate);
        } catch Error(string memory reason) {
            console.log("Failed to get redemption rate:", reason);
        } catch {
            console.log("Failed to get redemption rate: unknown error");
        }

        // Deploy the PTKHYPE/USD price oracle
        console.log("\nDeploying PtKhypeOracle...");
        PtUsdOracle pthypeUsdOracle =
            new PtUsdOracle(address(redemptionOracle), hypeUsdOracle, "PTKHYPE/USD Price Oracle");
        console.log("PtKhypeOracle deployed at:", address(pthypeUsdOracle));

        // Test the PTKHYPE/USD oracle
        try pthypeUsdOracle.latestAnswer() returns (int256 ptkhypeUsdPrice) {
            console.log("PTKHYPE/USD price:", ptkhypeUsdPrice);
        } catch Error(string memory reason) {
            console.log("Failed to get PTKHYPE/USD price:", reason);
        } catch {
            console.log("Failed to get PTKHYPE/USD price: unknown error");
        }

        // Get oracle metadata
        console.log("\nOracle Metadata:");
        console.log("Redemption Oracle Decimals:", redemptionOracle.decimals());
        console.log("PTKHYPE/USD Oracle Decimals:", pthypeUsdOracle.decimals());
        console.log("Redemption Oracle Description:", redemptionOracle.description());
        console.log("PTKHYPE/USD Oracle Description:", pthypeUsdOracle.description());

        // Summary
        console.log("\n=== Deployment Summary ===");
        console.log("PtKhypeRedemptionOracle:", address(redemptionOracle));
        console.log("PtKhypeOracle:", address(pthypeUsdOracle));
        console.log("HYPE/USD Oracle:", hypeUsdOracle);
        console.log("==========================");

        vm.stopBroadcast();
    }
}
