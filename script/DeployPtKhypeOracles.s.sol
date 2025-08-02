// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {PtKhypeRedemptionOracle} from "../src/oracle/PtKhypeRedemptionOracle.sol";
import {PtKhypeOracle} from "../src/oracle/PtKhypeOracle.sol";
import {console} from "forge-std/console.sol";

contract DeployPtKhypeOracles is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Get deployment parameters from environment variables
        address pendleOracle = vm.envAddress("PENDLE_ORACLE");
        address ptkhypeMarket = vm.envAddress("PTKHYPE_MARKET");
        address ptkhypeToken = vm.envAddress("PTKHYPE_TOKEN");
        address khypeToken = vm.envAddress("KHYPE_TOKEN");
        uint32 twapWindow = vm.envUint32("TWAP_WINDOW");
        address khypeUsdOracle = vm.envAddress("KHYPE_USD_ORACLE");

        console.log("Deployment Parameters:");
        console.log("Pendle Oracle:", pendleOracle);
        console.log("PTKHYPE Market:", ptkhypeMarket);
        console.log("PTKHYPE Token:", ptkhypeToken);
        console.log("KHYPE Token:", khypeToken);
        console.log("TWAP Window:", twapWindow);
        console.log("KHYPE/USD Oracle:", khypeUsdOracle);

        // Deploy the PTKHYPE/KHYPE redemption rate oracle
        console.log("\nDeploying PtKhypeRedemptionOracle...");
        PtKhypeRedemptionOracle redemptionOracle =
            new PtKhypeRedemptionOracle(pendleOracle, ptkhypeMarket, ptkhypeToken, khypeToken, twapWindow);
        console.log("PtKhypeRedemptionOracle deployed at:", address(redemptionOracle));

        // Test the redemption rate oracle
        try redemptionOracle.latestAnswer() returns (int256 redemptionRate) {
            console.log("Redemption rate (PTKHYPE/KHYPE):", redemptionRate);
        } catch Error(string memory reason) {
            console.log("Failed to get redemption rate:", reason);
        } catch {
            console.log("Failed to get redemption rate: unknown error");
        }

        // Deploy the PTKHYPE/USD price oracle
        console.log("\nDeploying PtKhypeOracle...");
        PtKhypeOracle ptkhypeUsdOracle = new PtKhypeOracle(address(redemptionOracle), khypeUsdOracle);
        console.log("PtKhypeOracle deployed at:", address(ptkhypeUsdOracle));

        // Test the PTKHYPE/USD oracle
        try ptkhypeUsdOracle.latestAnswer() returns (int256 ptkhypeUsdPrice) {
            console.log("PTKHYPE/USD price:", ptkhypeUsdPrice);
        } catch Error(string memory reason) {
            console.log("Failed to get PTKHYPE/USD price:", reason);
        } catch {
            console.log("Failed to get PTKHYPE/USD price: unknown error");
        }

        // Get oracle metadata
        console.log("\nOracle Metadata:");
        console.log("Redemption Oracle Decimals:", redemptionOracle.decimals());
        console.log("PTKHYPE/USD Oracle Decimals:", ptkhypeUsdOracle.decimals());
        console.log("Redemption Oracle Description:", redemptionOracle.description());
        console.log("PTKHYPE/USD Oracle Description:", ptkhypeUsdOracle.description());

        // Summary
        console.log("\n=== Deployment Summary ===");
        console.log("PtKhypeRedemptionOracle:", address(redemptionOracle));
        console.log("PtKhypeOracle:", address(ptkhypeUsdOracle));
        console.log("KHYPE/USD Oracle:", khypeUsdOracle);
        console.log("==========================");

        vm.stopBroadcast();
    }
}
