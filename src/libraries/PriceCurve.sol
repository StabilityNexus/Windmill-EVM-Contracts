// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { Order } from "../types/OrderTypes.sol";
import { MathUtils } from "./MathUtils.sol";

library PriceCurve {
    using MathUtils for uint256;

    function currentPrice(Order storage order, uint256 timestamp) internal view returns (uint256) {
        return _compute(
            order.startPrice,
            order.slope,
            order.createdAt,
            order.minPrice,
            order.maxPrice,
            timestamp
        );
    }

    function currentPriceAtTime(Order memory order, uint256 timestamp)
        internal
        pure
        returns (uint256)
    {
        return _compute(
            order.startPrice,
            order.slope,
            order.createdAt,
            order.minPrice,
            order.maxPrice,
            timestamp
        );
    }

    function isMatchable(Order memory buy, Order memory sell, uint256 timestamp)
        internal
        pure
        returns (bool)
    {
        return currentPriceAtTime(buy, timestamp) >= currentPriceAtTime(sell, timestamp);
    }

    function settlementPrice(Order memory buy, Order memory sell, uint256 timestamp)
        internal
        pure
        returns (uint256)
    {
        return MathUtils.midpoint(
            currentPriceAtTime(buy, timestamp), currentPriceAtTime(sell, timestamp)
        );
    }

    function _compute(
        uint256 startPrice,
        int256 slope,
        uint256 createdAt,
        uint256 minPrice,
        uint256 maxPrice,
        uint256 timestamp
    ) private pure returns (uint256) {
        uint256 elapsed = timestamp > createdAt ? timestamp - createdAt : 0;

        if (slope == 0 || elapsed == 0) {
            return MathUtils.clamp(startPrice, minPrice, maxPrice);
        }

        if (slope > 0) {
            uint256 posSlopeAbs = uint256(slope);

            unchecked {
                uint256 increment = posSlopeAbs * elapsed;

                if (increment / elapsed != posSlopeAbs) {
                    return MathUtils.clamp(
                        maxPrice != 0 ? maxPrice : type(uint256).max, minPrice, maxPrice
                    );
                }

                uint256 newPrice = startPrice + increment;

                if (newPrice < startPrice) {
                    return MathUtils.clamp(type(uint256).max, minPrice, maxPrice);
                }

                return MathUtils.clamp(newPrice, minPrice, maxPrice);
            }
        }

        if (slope == type(int256).min) {
            return MathUtils.clamp(minPrice, minPrice, maxPrice);
        }

        uint256 slopeAbs = uint256(-slope);

        unchecked {
            uint256 decrement = slopeAbs * elapsed;

            if (decrement / elapsed != slopeAbs) {
                return MathUtils.clamp(minPrice, minPrice, maxPrice);
            }

            uint256 price = decrement >= startPrice ? 0 : startPrice - decrement;

            return MathUtils.clamp(price, minPrice, maxPrice);
        }
    }
}
