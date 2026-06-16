// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { IPriceOracle } from "../../src/interfaces/IPriceOracle.sol";

contract MockPriceOracle is IPriceOracle {
    // Mapping: tokenIn => tokenOut => price
    mapping(address => mapping(address => uint256)) public prices;

    /// @notice Set price of tokenIn in terms of tokenOut.
    /// @param tokenIn The token to measure.
    /// @param tokenOut The unit of account token.
    /// @param price The rate (amount of tokenOut per unit of tokenIn).
    function setPrice(address tokenIn, address tokenOut, uint256 price) external {
        prices[tokenIn][tokenOut] = price;
    }

    /// @notice Get price of tokenIn in terms of tokenOut.
    /// @param tokenIn The token to measure.
    /// @param tokenOut The unit of account token.
    /// @return price The rate (amount of tokenOut per unit of tokenIn).
    function getPrice(address tokenIn, address tokenOut) external view override returns (uint256) {
        return prices[tokenIn][tokenOut];
    }
}
