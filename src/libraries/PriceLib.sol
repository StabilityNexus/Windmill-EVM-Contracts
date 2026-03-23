// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @notice Pure WAD price math for Windmill dutch auction orders not storage reads , no transfers - just the math

library PriceLib {
    /// @notice Returns the WAD price of an order at a given timestamp
    /// @param startPrice  WAD price at placeAt
    /// @param slope WAD/seconds; negative = buy , positive = sell
    /// @param endPrice the floor (for buy) or ceiling (for sell) price that the order will asymptotically approach but never cross
    /// @param placedAt block.timestamp when order was created
    /// @param endPriceTimestamp the timestamp to evaluate at (usually block.timestamp)

    function priceAt(
        uint256 startPrice,
        int256 slope,
        uint256 endPrice,
        uint256 placedAt,
        uint256 endPriceTimestamp
    ) internal pure returns (uint256) {


        uint256 timeElapsed = endPriceTimestamp - placedAt;

        uint256 absSlope = slope < 0 ? uint256(-slope) : uint256(slope);
        require(timeElapsed == 0 || absSlope <= type(uint256).max / timeElapsed, "PriceLib: slope * timeElapsed overflow");

        if (slope < 0) {
            // BUY order : price falls , slope is negative so we negate it
            uint256 decay = absSlope * timeElapsed;
            // Clamp : if decay exceeds startPrice, return 0 (fully decayed)
            uint256 raw = decay >= startPrice ? 0 : startPrice - decay;
            // never go below endPrice floor

            return raw < endPrice ? endPrice : raw;
        } else {
            // sell order : price rises
            uint256 raw = startPrice + absSlope * timeElapsed;
            // never go above endPrice ceiling
            return raw > endPrice ? endPrice : raw;
        }
    }

    /// @notice Returns true when price has hit its boundary and can move no further.An order AT boundary is still matchable if bp >= sp holds. Keeper must NOT skip boundary-price orders — always check bp >= sp directly.

    function atPriceBoundary(
        uint256 startPrice,
        int256 slope,
        uint256 endPrice,
        uint256 placedAt,
        uint256 endPriceTimestamp
    ) internal pure returns (bool) {
        uint256 currentPrice = priceAt(
            startPrice,
            slope,
            endPrice,
            placedAt,
            endPriceTimestamp
        );
        return currentPrice == endPrice;
    }
}
