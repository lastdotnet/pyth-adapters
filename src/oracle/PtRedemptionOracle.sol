// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.0;

import {PendleUniversalOracle} from "euler-price-oracle/adapter/pendle/PendleUniversalOracle.sol";

/**
 * @title PtRedemptionOracle
 * @notice Oracle for PT-KHYPE redemption value that inherits from PendleUniversalOracle
 * @dev Adds latestAnswer and decimals functions for compatibility with Chainlink-style oracles
 */
contract PtRedemptionOracle is PendleUniversalOracle {
    string public description;

    /**
     * @notice Constructor for PtRedemptionOracle
     * @param _pendleOracle Pendle oracle address
     * @param _pendleMarket Pendle market address for PT-KHYPE
     * @param _base Base asset address
     * @param _quote Quote asset address
     * @param _twapWindow TWAP window
     */
    constructor(address _pendleOracle, address _pendleMarket, address _base, address _quote, uint32 _twapWindow, string memory _description)
        PendleUniversalOracle(_pendleOracle, _pendleMarket, _base, _quote, _twapWindow)
    {
        description = _description;
    }

    /**
     * @notice Get the latest answer (price) from the oracle
     * @return answer The latest price as an int256
     */
    function latestAnswer() external view returns (int256 answer) {
        answer = int256(_getQuote(1e18, base, quote));
    }

    /**
     * @notice Get the decimals for the price
     * @return decimals The number of decimal places (typically 8 for Pendle oracles)
     */
    function decimals() external pure returns (uint8) {
        return 18;
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
        require(false, "Not implemented");
    }

    /**
     * @notice Get the version of the oracle
     * @return version The oracle version
     */
    function version() external pure returns (uint256) {
        return 1;
    }
}
