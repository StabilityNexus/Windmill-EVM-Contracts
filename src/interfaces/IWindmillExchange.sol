// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { Order } from "../types/OrderTypes.sol";

interface IWindmillExchange {
    event ProtocolFeeUpdated(address indexed treasury, uint256 protocolFeeBps);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function createOrder(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 startPrice,
        int256 slope,
        uint256 minPrice,
        uint256 maxPrice,
        uint256 expiry,
        bool isBuy
    ) external returns (uint256 orderId);

    function cancelOrder(uint256 orderId) external;

    function matchOrders(uint256 buyOrderId, uint256 sellOrderId, uint256 deadline) external;

    function matchOrdersBatch(
        uint256 orderId,
        uint256[] calldata counterOrderIds,
        uint256 deadline
    ) external;

    function setProtocolFee(address _treasury, uint256 _protocolFeeBps) external;

    function transferOwnership(address newOwner) external;

    function currentPrice(uint256 orderId, uint256 timestamp) external view returns (uint256 price);

    function getOrder(uint256 orderId) external view returns (Order memory);

    function getOrdersByPair(address tokenA, address tokenB, uint256 cursor, uint256 limit)
        external
        view
        returns (uint256[] memory);

    function totalOrders() external view returns (uint256);
}
