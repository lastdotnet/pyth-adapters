// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {PtRedemptionOracle} from "../src/oracle/PtRedemptionOracle.sol";
import {PtUsdOracle} from "../src/oracle/PtUsdOracle.sol";
import {PythAggregatorV3Standardized} from "src/PythAggregatorV3Standardized.sol";
import {IEACAggregatorProxy} from "src/oracle/interfaces/IEACAggregatorProxy.sol";
import {console} from "forge-std/console.sol";

contract DeployPtThbillOracle is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Get deployment parameters from environment variables
        address pendleOracle = 0x9a9Fa8338dd5E5B2188006f1Cd2Ef26d921650C2;
        address ptThbillMarket = 0x905A911E627EcCc7A0Ee3A30bb4f7e98501A1fB1;
        address ptThbillToken = 0xfdF1704a7D60Ab07D9889f33951633e7a80E34a3;
        address thbillToken = 0x9FD7466f987Fd4C45a5BBDe22ED8aba5BC8D72d1;
        uint256 twapWindow = 15 minutes;
        PythAggregatorV3Standardized susdeUsdOracle = new PythAggregatorV3Standardized(
            0xe9d69CdD6Fe41e7B621B4A688C5D1a68cB5c8ADc,
            0x6ec879b1e9963de5ee97e9c8710b742d6228252a5e2ca12d4ae81d7fe5ee8c5d,
            "USDe/USD Oracle"
        );

        require(twapWindow <= uint256(type(uint32).max), "TWAP window must be at most 2^32 - 1");

        console.log("Deployment Parameters:");
        console.log("Pendle Oracle:", pendleOracle);
        console.log("PTsUSDe Market:", ptSusdeMarket);
        console.log("PTsUSDe Token:", ptSusdeToken);
        console.log("sUSDe Token:", susdeToken);
        console.log("TWAP Window:", twapWindow);
        console.log("USDe/USD Oracle:", address(susdeUsdOracle));

        // Deploy the PTsUSDe/sUSDe redemption rate oracle
        console.log("\nDeploying PtSusdeRedemptionOracle...");
        PtRedemptionOracle redemptionOracle =
            new PtRedemptionOracle(pendleOracle, ptSusdeMarket, ptSusdeToken, susdeToken, uint32(twapWindow), "PTsUSDe/USDe Redemption Rate Oracle");
        console.log("PtRedemptionOracle deployed at:", address(redemptionOracle));

        // Test the redemption rate oracle
        try redemptionOracle.latestAnswer() returns (int256 redemptionRate) {
            console.log("Redemption rate (PTsUSDe/USDe):", redemptionRate);
        } catch Error(string memory reason) {
            console.log("Failed to get redemption rate:", reason);
        } catch {
            console.log("Failed to get redemption rate: unknown error");
        }

        // Deploy the PTsUSDe/USD price oracle
        console.log("\nDeploying PtSusdeOracle...");
        PtUsdOracle ptSusdeOracle = new PtUsdOracle(address(redemptionOracle), address(susdeUsdOracle), "PTsUSDe/USD Price Oracle");
        console.log("PtSusdeOracle deployed at:", address(ptSusdeOracle));

        // Test the PTsUSDe/USD oracle
        try ptSusdeOracle.latestAnswer() returns (int256 susdeUsdPrice) {
            console.log("PTsUSDe/USD price:", susdeUsdPrice);
        } catch Error(string memory reason) {
            console.log("Failed to get PTsUSDe/USD price:", reason);
        } catch {
            console.log("Failed to get PTsUSDe/USD price: unknown error");
        }

        // Get oracle metadata
        console.log("\nOracle Metadata:");
        console.log("Redemption Oracle Decimals:", redemptionOracle.decimals());
        console.log("PTsUSDe/USD Oracle Decimals:", susdeUsdOracle.decimals());
        console.log("Redemption Oracle Description:", redemptionOracle.description());
        console.log("PTsUSDe/USD Oracle Description:", susdeUsdOracle.description());

        // Summary
        console.log("\n=== Deployment Summary ===");
        console.log("PtSusdeRedemptionOracle:", address(redemptionOracle));
        console.log("PtSusdeOracle:", address(ptSusdeOracle));
        console.log("USDe/USD Oracle:", address(susdeUsdOracle));
        console.log("==========================");

        vm.stopBroadcast();
    }
}
