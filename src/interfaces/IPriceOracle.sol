// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IPriceOracle {
    /// @notice Gets the on-chain price of tokenIn in terms of tokenOut.
    /// @param tokenIn The token being sold/measured.
    /// @param tokenOut The token being bought/used as unit of account.
    /// @return price The exchange rate, represented as the amount of tokenOut per unit of tokenIn.
    function getPrice(address tokenIn, address tokenOut) external view returns (uint256);
}
