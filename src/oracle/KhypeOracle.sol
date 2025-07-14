// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {AggregatorV3Interface} from "src/oracle/interfaces/AggregatorV3Interface.sol";
import {IEACAggregatorProxy} from "src/oracle/interfaces/IEACAggregatorProxy.sol";

/**
 * @title KHYPEOracle
 * @author HypurrFi
 * @notice Oracle for KHYPE token
 * Price is calculated by:
 * 1. Getting HYPE/USD price from Pyth
 * 2. Getting the KHYPE/HYPE ratio using getExchangeRate()
 * Final price = (HYPE/KHYPE) * (HYPE/USD price)
 */
contract KhypeOracle is AggregatorV3Interface {
    IEACAggregatorProxy public constant HYPE_USD_PRICE_FEED = IEACAggregatorProxy(0x1d0E4EA616A749c1620118F7d97c111e8ec36E8b);
    IEACAggregatorProxy public constant K_HYPE_RR_FEED = IEACAggregatorProxy(0x4478c615e00fFb487aa269B2744Ef4E2DDD60851 );
    uint256 public constant PRECISION = 1e18;

    struct LatestAnswerLocals {
        int256 hypeUsdPrice;
        uint256 hypePerKhype;
        uint256 khypeUsdPrice;
    }

    /**
     * @notice Get the price of KHYPE in the base currency (ETH)
     * @return The price of KHYPE in the base currency (ETH)
     */
    function latestAnswer() external view returns (int256) {
        LatestAnswerLocals memory locals;

        locals.hypePerKhype = _getExchangeRate();

        locals.hypeUsdPrice = HYPE_USD_PRICE_FEED.latestAnswer();

        require(locals.hypeUsdPrice > 0, "HYPE/USD price is not positive");

        locals.khypeUsdPrice = locals.hypePerKhype * uint256(locals.hypeUsdPrice) / PRECISION;

        noInt256Overflow(locals.khypeUsdPrice, "KHYPE USD price int256 overflow");

        // USD price of KHYPE
        return int256(locals.khypeUsdPrice);
    }

    /// @notice Returns the latest round data
    function latestRoundData() external pure returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        require(false, "Not implemented");
        return (0, 0, 0, 0, 0);
    }

    /// @notice Returns the decimals of the oracle price
    function decimals() external view returns (uint8) {
        return K_HYPE_RR_FEED.decimals();
    }

    /// @notice Returns the description of the oracle
    function description() external pure returns (string memory) {
        return "KHYPE/USD Oracle";
    }

    /// @notice Version number of the oracle
    function version() external pure returns (uint256) {
        return 1;
    }

    function getRoundData(uint80) external pure returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) { 
        require(false, "Not implemented; No historical data for KHYPE/HYPE exchange rate");
        return (0, 0, 0, 0, 0);
    }

    function noInt256Overflow(uint256 a, string memory errorMessage) internal pure {
        require(a <= uint256(type(int256).max), errorMessage);
    }

    function _getExchangeRate() internal view returns (uint256) {
        int256 hypePerKhype = K_HYPE_RR_FEED.latestAnswer();
        require(hypePerKhype > 0, "KHYPE/HYPE exchange rate is not positive");
        return uint256(hypePerKhype) * PRECISION / (10 ** K_HYPE_RR_FEED.decimals());
    }
}
