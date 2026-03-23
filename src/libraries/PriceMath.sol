// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title PriceMath
 * @notice Deterministic linear lazy price: price = startPrice + slope * (timestamp - startTime).
 * @dev Pure library; no storage, no block.timestamp. Reverts if result would be negative (e.g. Dutch below zero).
 */
library PriceMath {
    error PriceMath_NegativePrice();
    error PriceMath_StartPriceOverflow();
    error PriceMath_TimestampElapsedOverflow();

    /// @notice Compute price at a given timestamp. Reverts if result < 0.
    /// @param startPrice Initial price (uint256).
    /// @param slope Change per second (int256; negative for Dutch).
    /// @param startTime Order start time.
    /// @param timestamp Time at which to evaluate (caller passes; no block.timestamp in library).
    /// @return Price as uint256; reverts if startPrice + slope * elapsed < 0.
    function priceAt(
        uint256 startPrice,
        int256 slope,
        uint256 startTime,
        uint256 timestamp
    ) internal pure returns (uint256) {
        if (timestamp <= startTime) {
            return startPrice;
        }
        uint256 elapsed = timestamp - startTime;
        // Ensure elapsed doesn't overflow int256
        if (elapsed > uint256(type(int256).max)) revert PriceMath_TimestampElapsedOverflow();
        int256 elapsedInt = int256(elapsed);
        if (startPrice > uint256(type(int256).max)) revert PriceMath_StartPriceOverflow();
        // forge-lint: disable-next-line(unsafe-typecast)
        int256 priceInt = int256(startPrice) + (slope * elapsedInt);
        if (priceInt < 0) revert PriceMath_NegativePrice();
        // forge-lint: disable-next-line(unsafe-typecast)
        return uint256(priceInt);
    }
}
