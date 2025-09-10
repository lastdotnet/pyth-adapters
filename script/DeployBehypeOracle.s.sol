// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {RedemptionUsdOracle} from "src/oracle/RedemptionUsdOracle.sol";

contract DeployBehypeOracle is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy RedemptionUsdOracle
        // You'll need to update these addresses with the actual oracle addresses
        address redemptionOracle = 0x5016c48F36f7e4C83b5C4D4b7227BFEf35Ae7688; // HYPE per beHYPE: https://app.redstone.finance/app/feeds/hyperevm/behype_fundamental/
        address underlyingUsdOracle = 0x1d0E4EA616A749c1620118F7d97c111e8ec36E8b; // USD per HYPE: https://app.hypurr.fi/markets/pooled/999/0xd8FC8F0b03eBA61F64D08B0bef69d80916E5DdA9
        string memory tokenSymbol = "beHYPE"; // Update with the appropriate token symbol

        RedemptionUsdOracle behypeOracle = new RedemptionUsdOracle(redemptionOracle, underlyingUsdOracle, tokenSymbol);

        console.log("RedemptionUsdOracle deployed at:", address(behypeOracle));
        console.log("Redemption Oracle:", redemptionOracle);
        console.log("Underlying USD Oracle:", underlyingUsdOracle);
        console.log("Token Symbol:", tokenSymbol);
        console.log("Redemption Rate:", RedemptionUsdOracle(behypeOracle).getRedemptionRate());
        console.log("Underlying USD Price:", RedemptionUsdOracle(behypeOracle).getUnderlyingUsdPrice());

        // Test the RedemptionUsdOracle
        try behypeOracle.latestAnswer() returns (int256 behypeUsdPrice) {
            console.log("BEHYPE/USD price:", uint256(behypeUsdPrice));
        } catch Error(string memory reason) {
            console.log("Failed to get BEHYPE/USD price:", reason);
        } catch {
            console.log("Failed to get BEHYPE/USD price: unknown error");
        }

        // Get oracle metadata
        console.log("\nOracle Metadata:");
        console.log("Redemption Oracle Decimals:", uint256(RedemptionUsdOracle(redemptionOracle).decimals()));
        console.log("BEHYPE/USD Oracle Decimals:", uint256(RedemptionUsdOracle(behypeOracle).decimals()));
        console.log("Redemption Oracle Description:", RedemptionUsdOracle(redemptionOracle).description());
        console.log("BEHYPE/USD Oracle Description:", RedemptionUsdOracle(behypeOracle).description());

        // Summary
        console.log("\n=== Deployment Summary ===");
        console.log("RedemptionUsdOracle:", address(behypeOracle));
        console.log("Redemption Oracle:", redemptionOracle);
        console.log("Underlying USD Oracle:", underlyingUsdOracle);
        console.log("Token Symbol:", tokenSymbol);
        console.log("==========================");

        vm.stopBroadcast();
    }
}
