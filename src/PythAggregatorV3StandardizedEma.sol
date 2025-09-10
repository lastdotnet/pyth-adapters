// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.0;

import {PythStructs} from "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";
import {IPyth} from "@pythnetwork/pyth-sdk-solidity/IPyth.sol";

// This interface is forked from the Zerolend Adapter found here:
// https://github.com/zerolend/pyth-oracles/blob/master/contracts/PythAggregatorV3.sol
// Original license found under licenses/zerolend-pyth-oracles.md

/**
 * @title A port of the ChainlinkAggregatorV3 interface that supports Pyth price feeds
 * @notice This does not store any roundId information on-chain. Please review the code before using this implementation.
 * Users should deploy an instance of this contract to wrap every price feed id that they need to use.
 */
contract PythAggregatorV3StandardizedEma {
    bytes32 public priceId;
    IPyth public pyth;
    string public description;

    constructor(address _pyth, bytes32 _priceId, string memory _description) {
        priceId = _priceId;
        pyth = IPyth(_pyth);
        description = _description;
    }

    // Wrapper function to update the underlying Pyth price feeds. Not part of the AggregatorV3 interface but useful.
    function updateFeeds(bytes[] calldata priceUpdateData) public payable {
        // Update the prices to the latest available values and pay the required fee for it. The `priceUpdateData` data
        // should be retrieved from our off-chain Price Service API using the `pyth-evm-js` package.
        // See section "How Pyth Works on EVM Chains" below for more information.
        uint256 fee = pyth.getUpdateFee(priceUpdateData);
        pyth.updatePriceFeeds{value: fee}(priceUpdateData);

        // refund remaining eth
        (bool success,) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "Refund failed");
    }

    function decimals() public view virtual returns (uint8) {
        return 8;
    }

    function version() public pure returns (uint256) {
        return 1;
    }

    function latestAnswer() public view virtual returns (int256) {
        PythStructs.Price memory priceFeed = pyth.getEmaPriceUnsafe(priceId);
        // scale the price to 8 decimals
        return _scalePriceTo8Decimals(priceFeed);
    }

    function latestTimestamp() public view returns (uint256) {
        PythStructs.Price memory price = pyth.getEmaPriceUnsafe(priceId);
        return price.publishTime;
    }

    function latestRound() public view returns (uint256) {
        // use timestamp as the round id
        return latestTimestamp();
    }

    function getAnswer(uint256) public view returns (int256) {
        return latestAnswer();
    }

    function getTimestamp(uint256) external view returns (uint256) {
        return latestTimestamp();
    }

    function getRoundData(uint80 _roundId)
        external
        pure
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        _roundId;
        require(false, "Not implemented");
        return (0, 0, 0, 0, 0);
    }

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        PythStructs.Price memory price = pyth.getEmaPriceUnsafe(priceId);
        roundId = uint80(price.publishTime);
        return (roundId, _scalePriceTo8Decimals(price), price.publishTime, price.publishTime, roundId);
    }

    function _scalePriceTo8Decimals(PythStructs.Price memory price) internal pure returns (int256) {
        require(price.expo < 0, "expo must be negative");
        price.expo = -1 * price.expo;
        if (price.expo < 8) {
            // scale up
            return price.price * int256(10 ** uint32(8 - price.expo));
        } else if (price.expo > 8) {
            // scale down
            return price.price / int256(10 ** uint32(price.expo - 8));
        }
        return price.price;
    }
}
