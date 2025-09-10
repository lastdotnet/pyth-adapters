// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {AggregatorV3Interface} from "src/oracle/interfaces/AggregatorV3Interface.sol";
import {IEACAggregatorProxy} from "src/oracle/interfaces/IEACAggregatorProxy.sol";

/**
 * @title RedemptionUsdOracle
 * @author HypurrFi
 * @notice Oracle for redemption rate and underlying/USD price
 * Price is calculated by:
 * 1. Getting redemption rate from the redemption oracle
 * 2. Getting underlying/USD price from the underlying oracle
 * Final price = redemption rate * underlying/USD price
 */
contract RedemptionUsdOracle is AggregatorV3Interface {
    uint256 public constant PRECISION = 1e8;

    address public immutable redemptionOracle;
    address public immutable underlyingUsdOracle;
    string public tokenSymbol;

    constructor(address _redemptionOracle, address _underlyingUsdOracle, string memory _tokenSymbol) {
        redemptionOracle = _redemptionOracle;
        underlyingUsdOracle = _underlyingUsdOracle;
        tokenSymbol = _tokenSymbol;
    }

    struct LatestAnswerLocals {
        uint256 redemptionRate;
        uint256 underlyingUsdPrice;
        uint256 redemptionUsdPrice;
    }

    /**
     * @notice Get the price of redemption rate and underlying/USD price
     * @return The price of KHYPE in the base currency (ETH)
     */
    function latestAnswer() external view returns (int256) {
        LatestAnswerLocals memory locals;

        locals.redemptionRate = _getRedemptionRate();

        locals.underlyingUsdPrice = _getUnderlyingUsdPrice();

        require(locals.underlyingUsdPrice > 0, "UNDERLYING/USD price is not positive");

        locals.redemptionUsdPrice = locals.redemptionRate * locals.underlyingUsdPrice / PRECISION;

        noInt256Overflow(locals.redemptionUsdPrice, "REDEMPTION USD price int256 overflow");

        // USD price of KHYPE
        return int256(locals.redemptionUsdPrice);
    }

    /// @notice Returns the latest round data
    function latestRoundData()
        external
        pure
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        require(false, "Not implemented");
        return (0, 0, 0, 0, 0);
    }

    /// @notice Returns the decimals of the oracle price
    function decimals() external view returns (uint8) {
        return IEACAggregatorProxy(redemptionOracle).decimals();
    }

    /// @notice Returns the description of the oracle
    function description() external view returns (string memory) {
        return string(abi.encodePacked(tokenSymbol, "/USD Oracle"));
    }

    /// @notice Version number of the oracle
    function version() external pure returns (uint256) {
        return 1;
    }

    function getRoundData(uint80)
        external
        pure
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        require(false, "Not implemented; No historical data for KHYPE/HYPE exchange rate");
        return (0, 0, 0, 0, 0);
    }

    function noInt256Overflow(uint256 a, string memory errorMessage) internal pure {
        require(a <= uint256(type(int256).max), errorMessage);
    }

    function getRedemptionRate() external view returns (uint256) {
        return _getRedemptionRate();
    }

    function _getRedemptionRate() internal view returns (uint256) {
        int256 underlyingPerRedemption = IEACAggregatorProxy(redemptionOracle).latestAnswer();
        require(underlyingPerRedemption > 0, "REDEMPTION rate is not positive");
        return uint256(underlyingPerRedemption) * PRECISION / (10 ** IEACAggregatorProxy(redemptionOracle).decimals());
    }

    function getUnderlyingUsdPrice() external view returns (uint256) {
        return _getUnderlyingUsdPrice();
    }

    function _getUnderlyingUsdPrice() internal view returns (uint256) {
        int256 underlyingUsdPrice = IEACAggregatorProxy(underlyingUsdOracle).latestAnswer();
        require(underlyingUsdPrice > 0, "UNDERLYING/USD price is not positive");
        return uint256(underlyingUsdPrice) * PRECISION / (10 ** IEACAggregatorProxy(underlyingUsdOracle).decimals());
    }
}
