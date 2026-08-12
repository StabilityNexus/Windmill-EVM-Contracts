// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { IPriceOracle } from "../../src/interfaces/IPriceOracle.sol";

contract MockPriceOracle is IPriceOracle {
    mapping(address => mapping(address => uint256)) public prices;

    function setPrice(address tokenIn, address tokenOut, uint256 price) external {
        prices[tokenIn][tokenOut] = price;
    }

    function getPrice(address tokenIn, address tokenOut) external view override returns (uint256) {
        return prices[tokenIn][tokenOut];
    }
}
