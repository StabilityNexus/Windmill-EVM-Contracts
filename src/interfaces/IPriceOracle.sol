// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IPriceOracle {
    function getPrice(address tokenIn, address tokenOut) external view returns (uint256);
}
