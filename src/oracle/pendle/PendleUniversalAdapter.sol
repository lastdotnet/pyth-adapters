// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.0;

import {IPMarket} from "euler-price-oracle/adapter/pendle/PendleUniversalOracle.sol";

import {IPMarket} from "@pendle/core-v2/interfaces/IPMarket.sol";
import {IPPrincipalToken} from "@pendle/core-v2/interfaces/IPPrincipalToken.sol";
import {IPPYLpOracle} from "@pendle/core-v2/interfaces/IPPYLpOracle.sol";
import {IStandardizedYield} from "@pendle/core-v2/interfaces/IStandardizedYield.sol";
import {PendlePYOracleLib} from "@pendle/core-v2/oracles/PendlePYOracleLib.sol";
import {PendleLpOracleLib} from "@pendle/core-v2/oracles/PendleLpOracleLib.sol";
import {Errors} from "@euler/price-oracle-v2/adapter/BaseAdapter.sol";
import {ScaleUtils, Scale} from "@euler/price-oracle-v2/lib/ScaleUtils.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";

/**
 * @title PendleUniversalOracleAdapter
 * @notice Adapter for Pendle Universal Oracle that provides external functions for dynamic fetching
 * @dev Allows fetching oracle data without hardcoding base/quote assets and other parameters
 */
contract PendleUniversalAdapter {
    string public constant name = "PendleUniversalAdapter";
    /// @dev The minimum length of the TWAP window.
    uint32 internal constant MIN_TWAP_WINDOW = 5 minutes;
    /// @dev The maximum length of the TWAP window.
    uint32 internal constant MAX_TWAP_WINDOW = 60 minutes;
    /// @notice The decimals of the Pendle Oracle. Fixed to 18.
    uint8 internal constant FEED_DECIMALS = 18;
    /// @notice The address of the Pendle oracle.
    address public immutable pendleOracle;

    /**
     * @notice Constructor for PendleUniversalOracleAdapter
     * @param _pendleOracle Pendle oracle address
     */
    constructor(address _pendleOracle) {
        require(_pendleOracle != address(0), "Invalid Pendle oracle");

        pendleOracle = _pendleOracle;
    }

    /**
     * @notice Get the price of base asset in quote asset
     * @param base Base asset address
     * @param quote Quote asset address
     * @param twapWindow TWAP window in seconds
     * @return price The price with 18 decimals
     */
    function getPrice(address pendleMarket, address base, address quote, uint32 twapWindow)
        external
        view
        returns (uint256 price)
    {
        price = _getQuote(1e18, pendleMarket, base, quote, twapWindow);
    }

    /**
     * @notice Get the quote amount for a given base amount
     * @param inAmount Amount of base asset (with 18 decimals)
     * @param pendleMarket Pendle market address
     * @param base Base asset address
     * @param quote Quote asset address
     * @param twapWindow TWAP window in seconds
     * @return quoteAmount The quote amount with 18 decimals
     */
    function getQuote(uint256 inAmount, address pendleMarket, address base, address quote, uint32 twapWindow)
        external
        view
        returns (uint256 quoteAmount)
    {
        return _getQuote(inAmount, pendleMarket, base, quote, twapWindow);
    }

    /**
     * @notice Get the decimals for the price
     * @return decimals The number of decimal places (18 for Pendle oracles)
     */
    function decimals() external pure returns (uint8) {
        return 18;
    }

    /**
     * @notice Get the description of the oracle
     * @param base Base asset address
     * @param quote Quote asset address
     * @return description The oracle description
     */
    function description(address base, address quote) external pure returns (string memory) {
        return string(abi.encodePacked("Pendle Oracle: ", _addressToString(base), "/", _addressToString(quote)));
    }

    /**
     * @notice Get the version of the oracle
     * @return version The oracle version
     */
    function version() external pure returns (uint256) {
        return 1;
    }

    /**
     * @notice Get the quote amount for a given base amount (internal function)
     * @param inAmount The amount of `base` to convert.
     * @param base Base asset address
     * @param quote Quote asset address
     * @param twapWindow TWAP window in seconds
     * @return quoteAmount The quote amount
     */
    function _getQuote(uint256 inAmount, address pendleMarket, address base, address quote, uint32 twapWindow)
        internal
        view
        returns (uint256 quoteAmount)
    {
        _validateTwapWindow(twapWindow, pendleOracle, pendleMarket);

        (address _base, address _quote) = _getBaseAndQuote(pendleMarket, base, quote);
        bool inverse = ScaleUtils.getDirectionOrRevert(base, _base, quote, _quote);
        uint256 unitPrice = _getRateFunction(pendleMarket, _base, _quote)(IPMarket(pendleMarket), twapWindow);
        return ScaleUtils.calcOutAmount(inAmount, unitPrice, _getScale(_base, _quote), inverse);
    }

    /**
     * @notice Convert address to string
     * @param addr Address to convert
     * @return String representation of the address
     */
    function _addressToString(address addr) internal pure returns (string memory) {
        bytes memory b = new bytes(20);
        for (uint256 i = 0; i < 20; i++) {
            b[i] = bytes1(uint8(uint160(addr) / (2 ** (8 * (19 - i)))));
        }
        return string(b);
    }

    function _validateTwapWindow(uint32 twapWindow, address pendleOracle, address pendleMarket) internal view {
        if (twapWindow < MIN_TWAP_WINDOW || twapWindow > MAX_TWAP_WINDOW) {
            revert Errors.PriceOracle_InvalidConfiguration();
        }

        // Verify that the observations buffer is adequately sized and populated.
        (bool increaseCardinalityRequired,, bool oldestObservationSatisfied) =
            IPPYLpOracle(pendleOracle).getOracleState(pendleMarket, twapWindow);
        if (increaseCardinalityRequired || !oldestObservationSatisfied) {
            revert Errors.PriceOracle_InvalidConfiguration();
        }
    }

    function _getRateFunction(address pendleMarket, address base, address quote)
        internal
        view
        returns (function(IPMarket, uint32) view returns (uint256))
    {
        (IStandardizedYield sy, IPPrincipalToken pt,) = IPMarket(pendleMarket).readTokens();
        if (base == address(pt)) {
            if (quote == address(sy)) {
                return PendlePYOracleLib.getPtToSyRate;
            } else {
                return PendlePYOracleLib.getPtToAssetRate;
            }
        } else if (base == pendleMarket) {
            if (quote == address(sy)) {
                return PendleLpOracleLib.getLpToSyRate;
            } else {
                return PendleLpOracleLib.getLpToAssetRate;
            }
        } else {
            revert Errors.PriceOracle_InvalidConfiguration();
        }
    }

    function _getScale(address base, address quote) internal view returns (Scale) {
        uint8 baseDecimals = _getDecimals(base);
        uint8 quoteDecimals = _getDecimals(quote);
        return ScaleUtils.calcScale(baseDecimals, quoteDecimals, FEED_DECIMALS);
    }

    function _getBaseAndQuote(address pendleMarket, address base, address quote)
        internal
        view
        returns (address, address)
    {
        (IStandardizedYield sy, IPPrincipalToken pt,) = IPMarket(pendleMarket).readTokens();
        if (base == address(pt)) {
            if (quote == address(sy)) {
                return (address(pt), address(sy));
            } else {
                return (address(pt), quote);
            }
        } else if (base == pendleMarket) {
            if (quote == address(sy)) {
                return (pendleMarket, address(sy));
            } else {
                return (pendleMarket, quote);
            }
        }

        if (base == address(sy)) {
            return (base, address(sy));
        } else {
            return (base, address(pt));
        }

        revert Errors.PriceOracle_InvalidConfiguration();
    }

    function _getDecimals(address asset) internal view returns (uint8) {
        if (asset == address(0)) {
            return 18;
        }
        return IERC20(asset).decimals();
    }
}
