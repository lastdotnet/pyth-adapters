// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.0;

import {AggregatorV3Interface} from "src/oracle/interfaces/AggregatorV3Interface.sol";
import {IEACAggregatorProxy} from "src/oracle/interfaces/IEACAggregatorProxy.sol";
import {PendleUniversalOracle} from "euler-price-oracle/adapter/pendle/PendleUniversalOracle.sol";

/**
 * @title PtUsdOracle
 * @notice Oracle for PT/USD price that combines redemption rate and UNDERLYING/USD price
 * @dev Calculates PT/USD = (PT/UNDERLYING) * (UNDERLYING/USD)
 */
contract PtUsdOracle {
    // State variables
    address public immutable redemptionOracle; // PT/UNDERLYING redemption rate oracle
    address public immutable underlyingUsdOracle; // UNDERLYING/USD price oracle
    uint8 public constant DECIMALS = 8;
    string public description;

    // Events
    event PriceUpdated(uint256 ptUsdPrice, uint256 redemptionRate, uint256 underlyingUsdPrice);

    /**
     * @notice Constructor for PtUsdOracle
     * @param _redemptionOracle Address of PT/UNDERLYING redemption rate oracle
     * @param _underlyingUsdOracle Address of UNDERLYING/USD price oracle
     */
    constructor(address _redemptionOracle, address _underlyingUsdOracle, string memory _description) {
        require(_redemptionOracle != address(0), "Invalid redemption oracle");
        require(_underlyingUsdOracle != address(0), "Invalid UNDERLYING/USD oracle");

        redemptionOracle = _redemptionOracle;
        underlyingUsdOracle = _underlyingUsdOracle;
        description = _description;
    }

    struct LatestAnswerLocals {
        int256 ptUsdPrice;
        uint256 underlyingPerPt;
        uint256 underlyingUsdPrice;
        uint8 redemptionRateDecimals;
        uint8 underlyingUsdDecimals;
    }

    /**
     * @notice Get the price of UNDERLYING in the base currency (ETH)
     * @return The price of UNDERLYING in the base currency (ETH)
     */
    function latestAnswer() public view returns (int256) {
        LatestAnswerLocals memory locals;

        (locals.underlyingPerPt, locals.redemptionRateDecimals) = _getRedemptionRate();

        (locals.underlyingUsdPrice, locals.underlyingUsdDecimals) = _getUnderlyingUsdPrice();

        require(locals.underlyingUsdPrice > 0, "UNDERLYING/USD price is not positive");

        locals.underlyingUsdPrice =
            locals.underlyingPerPt * uint256(locals.underlyingUsdPrice) / (10 ** locals.redemptionRateDecimals);

        noInt256Overflow(locals.underlyingUsdPrice, "UNDERLYING USD price int256 overflow");

        // USD price of UNDERLYING
        return int256(locals.underlyingUsdPrice);
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
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        try this.latestAnswer() returns (int256 price) {
            return (
                1, // roundId
                price, // answer
                block.timestamp, // startedAt
                block.timestamp, // updatedAt
                1 // answeredInRound
            );
        } catch {
            return (
                1, // roundId
                0, // answer
                block.timestamp, // startedAt
                block.timestamp, // updatedAt
                1 // answeredInRound
            );
        }
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
    function _getRedemptionRate() internal view returns (uint256 rate, uint8 rateDecimals) {
        try IEACAggregatorProxy(redemptionOracle).latestAnswer() returns (int256 answer) {
            require(answer > 0, "Invalid redemption rate");
            return (uint256(answer), AggregatorV3Interface(redemptionOracle).decimals());
        } catch {
            revert("Failed to get redemption rate");
        }
    }

    /**
     * @notice Get the UNDERLYING/USD price from the oracle
     * @return price The UNDERLYING/USD price with 8 decimals
     */
    function _getUnderlyingUsdPrice() internal view returns (uint256 price, uint8 priceDecimals) {
        try IEACAggregatorProxy(underlyingUsdOracle).latestAnswer() returns (int256 answer) {
            require(answer > 0, "Invalid UNDERLYING/USD price");
            return (uint256(answer), AggregatorV3Interface(underlyingUsdOracle).decimals());
        } catch {
            revert("Failed to get UNDERLYING/USD price");
        }
    }

    function noInt256Overflow(uint256 a, string memory errorMessage) internal pure {
        require(a <= uint256(type(int256).max), errorMessage);
    }
}
