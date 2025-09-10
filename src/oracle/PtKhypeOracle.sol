// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.0;

import {AggregatorV3Interface} from "src/oracle/interfaces/AggregatorV3Interface.sol";
import {IEACAggregatorProxy} from "src/oracle/interfaces/IEACAggregatorProxy.sol";
import {PendleUniversalOracle} from "euler-price-oracle/adapter/pendle/PendleUniversalOracle.sol";

/**
 * @title PtKhypeOracle
 * @notice Oracle for PTKHYPE/USD price that combines redemption rate and KHYPE/USD price
 * @dev Calculates PTKHYPE/USD = (PTKHYPE/KHYPE) * (KHYPE/USD)
 */
contract PtKhypeOracle {
    // State variables
    address public immutable redemptionOracle; // PTKHYPE/KHYPE redemption rate oracle
    address public immutable khypeUsdOracle; // KHYPE/USD price oracle
    uint8 public constant DECIMALS = 8;

    // Events
    event PriceUpdated(uint256 ptkhypeUsdPrice, uint256 redemptionRate, uint256 khypeUsdPrice);

    /**
     * @notice Constructor for PtKhypeOracle
     * @param _redemptionOracle Address of PTKHYPE/KHYPE redemption rate oracle
     * @param _khypeUsdOracle Address of KHYPE/USD price oracle
     */
    constructor(address _redemptionOracle, address _khypeUsdOracle) {
        require(_redemptionOracle != address(0), "Invalid redemption oracle");
        require(_khypeUsdOracle != address(0), "Invalid KHYPE/USD oracle");

        redemptionOracle = _redemptionOracle;
        khypeUsdOracle = _khypeUsdOracle;
    }

    struct LatestAnswerLocals {
        int256 ptKhypeUsdPrice;
        uint256 khypePerPtKhype;
        uint256 khypeUsdPrice;
        uint8 redemptionRateDecimals;
        uint8 khypeUsdDecimals;
    }

    /**
     * @notice Get the price of KHYPE in the base currency (ETH)
     * @return The price of KHYPE in the base currency (ETH)
     */
    function latestAnswer() external view returns (int256) {
        LatestAnswerLocals memory locals;

        (locals.khypePerPtKhype, locals.redemptionRateDecimals) = _getRedemptionRate();

        (locals.khypeUsdPrice, locals.khypeUsdDecimals) = _getKhypeUsdPrice();

        require(locals.khypeUsdPrice > 0, "HYPE/USD price is not positive");

        locals.khypeUsdPrice =
            locals.khypePerPtKhype * uint256(locals.khypeUsdPrice) / (10 ** locals.redemptionRateDecimals);

        noInt256Overflow(locals.khypeUsdPrice, "KHYPE USD price int256 overflow");

        // USD price of KHYPE
        return int256(locals.khypeUsdPrice);
    }

    /**
     * @notice Get the decimals for the price
     * @return decimals The number of decimal places (8 for USD prices)
     */
    function decimals() external pure returns (uint8) {
        return DECIMALS;
    }

    /**
     * @notice Get the latest round data (Chainlink-style interface)
     * @return roundId The round ID (always 1 for this oracle)
     * @return answer The latest price
     * @return startedAt Timestamp when the round started
     * @return updatedAt Timestamp when the round was updated
     * @return answeredInRound The round ID in which the answer was computed
     */
    function latestRoundData()
        external
        pure
        returns (
            uint80, /*roundId*/
            int256, /*answer*/
            uint256, /*startedAt*/
            uint256, /*updatedAt*/
            uint80 /*answeredInRound*/
        )
    {
        require(false, "Not implemented");
        return (0, 0, 0, 0, 0);
    }

    /**
     * @notice Get the description of the oracle
     * @return description The oracle description
     */
    function description() external pure returns (string memory) {
        return "PTKHYPE/USD Price Oracle";
    }

    /**
     * @notice Get the version of the oracle
     * @return version The oracle version
     */
    function version() external pure returns (uint256) {
        return 1;
    }

    /**
     * @notice Get the redemption rate from the PTKHYPE/KHYPE oracle
     * @return rate The redemption rate with 18 decimals
     */
    function _getRedemptionRate() internal view returns (uint256, uint8) {
        try IEACAggregatorProxy(redemptionOracle).latestAnswer() returns (int256 answer) {
            require(answer > 0, "Invalid redemption rate");
            return (uint256(answer), AggregatorV3Interface(redemptionOracle).decimals());
        } catch {
            revert("Failed to get redemption rate");
        }
    }

    /**
     * @notice Get the KHYPE/USD price from the oracle
     */
    function _getKhypeUsdPrice() internal view returns (uint256, uint8) {
        try IEACAggregatorProxy(khypeUsdOracle).latestAnswer() returns (int256 answer) {
            require(answer > 0, "Invalid KHYPE/USD price");
            return (uint256(answer), AggregatorV3Interface(khypeUsdOracle).decimals());
        } catch {
            revert("Failed to get KHYPE/USD price");
        }
    }

    function noInt256Overflow(uint256 a, string memory errorMessage) internal pure {
        require(a <= uint256(type(int256).max), errorMessage);
    }
}
