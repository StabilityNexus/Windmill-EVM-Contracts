// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { IERC20 } from "../interfaces/IERC20.sol";
import { Order, OrderType } from "../types/OrderTypes.sol";
import { OrderStorage } from "../storage/OrderStorage.sol";
import { PairStorage } from "../storage/PairStorage.sol";
import { PriceCurve } from "../libraries/PriceCurve.sol";
import { TokenTransfer } from "../libraries/TokenTransfer.sol";
import { MathUtils } from "../libraries/MathUtils.sol";
import { IWindmillExchange } from "../interfaces/IWindmillExchange.sol";
import { IPriceOracle } from "../interfaces/IPriceOracle.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

error ZeroAddress();
error SameToken();
error ZeroAmount();
error ZeroStartPrice();
error InvalidExpiry();
error InvalidPriceBounds();
error SlopeOverflow();
error NotMaker();
error OrderInactive();
error OrderExpired();
error SelfMatch();
error OrdersNotMatchable();
error PairMismatch();
error ZeroSettlementPrice();
error UnsupportedTokenBehavior();

error NotOwner();
error ExchangePaused();
error InvalidProtocolFee();
error MismatchedValue();
error NativeEthNotSupported();
error EthTransferFailed();

error OracleNotSet();
error TriggerConditionNotMet(uint256 orderId);

interface IWETH {
    function deposit() external payable;
    function withdraw(uint256) external;
}

contract WindmillExchange is OrderStorage, PairStorage, IWindmillExchange, ReentrancyGuard {
    address public owner;
    bool public paused;
    address public immutable WETH;
    address public treasury;
    uint256 public protocolFeeBps;
    address public override priceOracle;

    event Paused(address indexed by);
    event Unpaused(address indexed by);

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    modifier whenNotPaused() {
        if (paused) revert ExchangePaused();
        _;
    }

    constructor(address _weth) {
        if (_weth == address(0)) revert ZeroAddress();
        owner = msg.sender;
        WETH = _weth;
    }

    receive() external payable { }

    function pause() external onlyOwner {
        paused = true;
        emit Paused(msg.sender);
    }

    function unpause() external onlyOwner {
        paused = false;
        emit Unpaused(msg.sender);
    }

    function setProtocolFee(address _treasury, uint256 _protocolFeeBps)
        external
        override
        onlyOwner
    {
        if (_protocolFeeBps > 500) revert InvalidProtocolFee();
        if (_protocolFeeBps > 0 && _treasury == address(0)) revert ZeroAddress();
        treasury = _treasury;
        protocolFeeBps = _protocolFeeBps;
        emit ProtocolFeeUpdated(_treasury, _protocolFeeBps);
    }

    function transferOwnership(address newOwner) external override onlyOwner {
        if (newOwner == address(0)) revert ZeroAddress();
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function setPriceOracle(address _oracle) external override onlyOwner {
        priceOracle = _oracle;
        emit PriceOracleUpdated(_oracle);
    }

    function _safeTransferTokenOrETH(address token, address to, uint256 amount) internal {
        if (token == WETH) {
            IWETH(WETH).withdraw(amount);
            (bool success,) = to.call{ value: amount }("");
            if (!success) revert EthTransferFailed();
        } else {
            TokenTransfer.safeTransfer(token, to, amount);
        }
    }

    event OrderCreated(
        uint256 indexed orderId,
        address indexed maker,
        address indexed tokenIn,
        address tokenOut,
        uint256 amountIn,
        bool isBuy
    );
    event OrderCancelled(uint256 indexed orderId, address indexed maker, uint256 refund);
    event OrderMatched(
        uint256 indexed buyOrderId,
        uint256 indexed sellOrderId,
        address indexed keeper,
        uint256 settlementPrice,
        uint256 executedQuantity
    );
    event OrderFilled(uint256 indexed orderId);
    event OrderPartiallyFilled(uint256 indexed orderId, uint256 remainingIn);

    uint256 private constant MAX_LIFETIME = 315_360_000;
    uint256 private constant MAX_PAGE_SIZE = 500;
    uint256 private constant SLOPE_ABS_LIMIT = type(uint128).max / MAX_LIFETIME;

    function createOrder(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 startPrice,
        int256 slope,
        uint256 minPrice,
        uint256 maxPrice,
        uint256 expiry,
        bool isBuy,
        OrderType orderType,
        uint256 triggerPrice
    ) public payable override nonReentrant whenNotPaused returns (uint256 orderId) {
        // Checks
        if (tokenIn == address(0) || tokenOut == address(0)) revert ZeroAddress();
        if (tokenIn == tokenOut) revert SameToken();
        if (amountIn == 0) revert ZeroAmount();
        if (startPrice == 0) revert ZeroStartPrice();
        if (expiry != 0 && expiry <= block.timestamp) revert InvalidExpiry();
        if (maxPrice != 0 && maxPrice < minPrice) revert InvalidPriceBounds();
        if (slope != 0 && MathUtils.abs(slope) > SLOPE_ABS_LIMIT) revert SlopeOverflow();
        if (orderType != OrderType.LIMIT && triggerPrice == 0) revert InvalidPriceBounds();

        // Effects — store and register BEFORE the external transfer (CEI)
        Order memory order = Order({
            id: 0,
            maker: msg.sender,
            isBuy: isBuy,
            active: true,
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            amountIn: amountIn,
            remainingIn: amountIn,
            startPrice: startPrice,
            slope: slope,
            minPrice: minPrice,
            maxPrice: maxPrice,
            createdAt: block.timestamp,
            expiry: expiry,
            orderType: orderType,
            triggerPrice: triggerPrice
        });

        orderId = _storeOrder(order);
        _addOrderToPair(tokenIn, tokenOut, orderId);

        // Interactions
        if (tokenIn == WETH && msg.value > 0) {
            if (msg.value != amountIn) revert MismatchedValue();
            IWETH(WETH).deposit{ value: msg.value }();
        } else {
            if (msg.value > 0) revert NativeEthNotSupported();
            uint256 balBefore = IERC20(tokenIn).balanceOf(address(this));
            TokenTransfer.safeTransferFrom(tokenIn, msg.sender, address(this), amountIn);
            if (IERC20(tokenIn).balanceOf(address(this)) - balBefore != amountIn) {
                revert UnsupportedTokenBehavior();
            }
        }

        emit OrderCreated(orderId, msg.sender, tokenIn, tokenOut, amountIn, isBuy);
    }

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
    ) external payable override returns (uint256 orderId) {
        return createOrder(
            tokenIn,
            tokenOut,
            amountIn,
            startPrice,
            slope,
            minPrice,
            maxPrice,
            expiry,
            isBuy,
            OrderType.LIMIT,
            0
        );
    }

    function cancelOrder(uint256 orderId) external override nonReentrant {
        Order storage order = _getOrder(orderId);

        if (order.maker != msg.sender) revert NotMaker();
        if (!order.active) revert OrderInactive();

        uint256 refund = order.remainingIn;
        address tokenIn = order.tokenIn;
        address tokenOut = order.tokenOut;

        // Effects before interaction
        _deactivateOrder(orderId);
        _removeOrderFromPair(tokenIn, tokenOut, orderId);

        // Interaction
        _safeTransferTokenOrETH(tokenIn, msg.sender, refund);

        emit OrderCancelled(orderId, msg.sender, refund);
    }

    function matchOrders(uint256 buyOrderId, uint256 sellOrderId, uint256 deadline)
        external
        override
        nonReentrant
        whenNotPaused
    {
        require(block.timestamp <= deadline, "Keeper deadline expired");
        Order memory buy = _getOrderMem(buyOrderId);
        Order memory sell = _getOrderMem(sellOrderId);

        _validateMatch(buy, sell, block.timestamp);

        (
            uint256 settlementPrice,
            uint256 executedQuantity,
            uint256 notionalAmount,
            bool buyFilled,
            bool sellFilled
        ) = _computeSettlement(buy, sell, block.timestamp);

        uint256 newBuyRemaining = buy.remainingIn - notionalAmount;
        uint256 newSellRemaining = sell.remainingIn - executedQuantity;

        // Effects
        if (buyFilled) {
            _deactivateOrder(buyOrderId);
            _removeOrderFromPair(buy.tokenIn, buy.tokenOut, buyOrderId);
            emit OrderFilled(buyOrderId);
        } else {
            _updateRemainingIn(buyOrderId, newBuyRemaining);
            emit OrderPartiallyFilled(buyOrderId, newBuyRemaining);
        }

        if (sellFilled) {
            _deactivateOrder(sellOrderId);
            _removeOrderFromPair(sell.tokenIn, sell.tokenOut, sellOrderId);
            emit OrderFilled(sellOrderId);
        } else {
            _updateRemainingIn(sellOrderId, newSellRemaining);
            emit OrderPartiallyFilled(sellOrderId, newSellRemaining);
        }

        // Interactions
        uint256 keeperFee = notionalAmount / 1000; // 0.1%
        uint256 protocolFee = (notionalAmount * protocolFeeBps) / 10000;

        _safeTransferTokenOrETH(sell.tokenIn, buy.maker, executedQuantity);
        _safeTransferTokenOrETH(buy.tokenIn, sell.maker, notionalAmount - keeperFee - protocolFee);
        _safeTransferTokenOrETH(buy.tokenIn, msg.sender, keeperFee);
        if (protocolFee > 0 && treasury != address(0)) {
            _safeTransferTokenOrETH(buy.tokenIn, treasury, protocolFee);
        }

        emit OrderMatched(buyOrderId, sellOrderId, msg.sender, settlementPrice, executedQuantity);
    }

    function matchOrdersBatch(uint256 orderId, uint256[] calldata counterOrderIds, uint256 deadline)
        external
        override
        nonReentrant
        whenNotPaused
    {
        require(block.timestamp <= deadline, "Keeper deadline expired");
        uint256 len = counterOrderIds.length;
        require(len > 0, "Empty counter orders");

        Order memory primaryOrder = _getOrderMem(orderId);
        if (!primaryOrder.active) revert OrderInactive();

        uint256 startRemainingIn = primaryOrder.remainingIn;

        for (uint256 i = 0; i < len; i++) {
            if (!primaryOrder.active) {
                break;
            }

            (
                ,
                uint256 executedQuantity,
                uint256 notionalAmount,
                bool buyFilled,
                bool sellFilled
            ) = _matchStep(primaryOrder, counterOrderIds[i], orderId);

            if (primaryOrder.isBuy) {
                primaryOrder.remainingIn -= notionalAmount;
                primaryOrder.active = !buyFilled;
            } else {
                primaryOrder.remainingIn -= executedQuantity;
                primaryOrder.active = !sellFilled;
            }
        }

        if (primaryOrder.remainingIn != startRemainingIn) {
            if (!primaryOrder.active) {
                _deactivateOrder(orderId);
                _removeOrderFromPair(primaryOrder.tokenIn, primaryOrder.tokenOut, orderId);
                emit OrderFilled(orderId);
            } else {
                _updateRemainingIn(orderId, primaryOrder.remainingIn);
                emit OrderPartiallyFilled(orderId, primaryOrder.remainingIn);
            }
        }
    }

    function _matchStep(
        Order memory primaryOrder,
        uint256 counterOrderId,
        uint256 orderId
    ) private returns (
        uint256 settlementPrice,
        uint256 executedQuantity,
        uint256 notionalAmount,
        bool buyFilled,
        bool sellFilled
    ) {
        Order memory counterOrder = _getOrderMem(counterOrderId);

        if (primaryOrder.isBuy) {
            _validateMatch(primaryOrder, counterOrder, block.timestamp);
            (settlementPrice, executedQuantity, notionalAmount, buyFilled, sellFilled) =
                _computeSettlement(primaryOrder, counterOrder, block.timestamp);

            if (sellFilled) {
                _deactivateOrder(counterOrderId);
                _removeOrderFromPair(counterOrder.tokenIn, counterOrder.tokenOut, counterOrderId);
                emit OrderFilled(counterOrderId);
            } else {
                uint256 rem = counterOrder.remainingIn - executedQuantity;
                _updateRemainingIn(counterOrderId, rem);
                emit OrderPartiallyFilled(counterOrderId, rem);
            }

            uint256 keeperFee = notionalAmount / 1000;
            uint256 protocolFee = (notionalAmount * protocolFeeBps) / 10000;

            _safeTransferTokenOrETH(counterOrder.tokenIn, primaryOrder.maker, executedQuantity);
            _safeTransferTokenOrETH(
                primaryOrder.tokenIn, counterOrder.maker, notionalAmount - keeperFee - protocolFee
            );
            _safeTransferTokenOrETH(primaryOrder.tokenIn, msg.sender, keeperFee);
            if (protocolFee > 0 && treasury != address(0)) {
                _safeTransferTokenOrETH(primaryOrder.tokenIn, treasury, protocolFee);
            }

            emit OrderMatched(
                orderId, counterOrderId, msg.sender, settlementPrice, executedQuantity
            );
        } else {
            _validateMatch(counterOrder, primaryOrder, block.timestamp);
            (settlementPrice, executedQuantity, notionalAmount, buyFilled, sellFilled) =
                _computeSettlement(counterOrder, primaryOrder, block.timestamp);

            if (buyFilled) {
                _deactivateOrder(counterOrderId);
                _removeOrderFromPair(counterOrder.tokenIn, counterOrder.tokenOut, counterOrderId);
                emit OrderFilled(counterOrderId);
            } else {
                uint256 rem = counterOrder.remainingIn - notionalAmount;
                _updateRemainingIn(counterOrderId, rem);
                emit OrderPartiallyFilled(counterOrderId, rem);
            }

            uint256 keeperFee = notionalAmount / 1000;
            uint256 protocolFee = (notionalAmount * protocolFeeBps) / 10000;

            _safeTransferTokenOrETH(primaryOrder.tokenIn, counterOrder.maker, executedQuantity);
            _safeTransferTokenOrETH(
                counterOrder.tokenIn, primaryOrder.maker, notionalAmount - keeperFee - protocolFee
            );
            _safeTransferTokenOrETH(counterOrder.tokenIn, msg.sender, keeperFee);
            if (protocolFee > 0 && treasury != address(0)) {
                _safeTransferTokenOrETH(counterOrder.tokenIn, treasury, protocolFee);
            }

            emit OrderMatched(
                counterOrderId, orderId, msg.sender, settlementPrice, executedQuantity
            );
        }
    }

    function currentPrice(uint256 orderId, uint256 timestamp)
        external
        view
        override
        returns (uint256)
    {
        return PriceCurve.currentPriceAtTime(_getOrderMem(orderId), timestamp);
    }

    function getOrder(uint256 orderId) external view override returns (Order memory) {
        return _getOrderMem(orderId);
    }

    function getOrdersByPair(address tokenA, address tokenB, uint256 cursor, uint256 limit)
        external
        view
        override
        returns (uint256[] memory)
    {
        if (limit > MAX_PAGE_SIZE) {
            limit = MAX_PAGE_SIZE;
        }
        uint256[] memory all = _getOrdersByPair(tokenA, tokenB);
        uint256 total = all.length;

        if (cursor >= total) {
            return new uint256[](0);
        }

        uint256 remaining = total - cursor;
        uint256 size = remaining < limit ? remaining : limit;

        uint256[] memory result = new uint256[](size);

        for (uint256 i; i < size; i++) {
            result[i] = all[cursor + i];
        }

        return result;
    }

    function totalOrders() external view override returns (uint256) {
        return _totalOrders();
    }

    function _validateMatch(Order memory buy, Order memory sell, uint256 ts) private view {
        if (!buy.active) revert OrderInactive();
        if (!sell.active) revert OrderInactive();
        if (buy.expiry != 0 && ts > buy.expiry) revert OrderExpired();
        if (sell.expiry != 0 && ts > sell.expiry) revert OrderExpired();
        if (!buy.isBuy || sell.isBuy) revert PairMismatch();
        if (buy.tokenOut != sell.tokenIn || buy.tokenIn != sell.tokenOut) revert PairMismatch();
        if (buy.maker == sell.maker) revert SelfMatch();
        _checkConditionalTrigger(buy);
        _checkConditionalTrigger(sell);
        if (!PriceCurve.isMatchable(buy, sell, ts)) revert OrdersNotMatchable();
    }

    function _checkConditionalTrigger(Order memory order) private view {
        if (order.orderType == OrderType.LIMIT) {
            return;
        }

        if (priceOracle == address(0)) revert OracleNotSet();

        uint256 marketPrice = IPriceOracle(priceOracle).getPrice(order.tokenIn, order.tokenOut);

        if (order.orderType == OrderType.STOP_LOSS) {
            if (marketPrice > order.triggerPrice) revert TriggerConditionNotMet(order.id);
        } else if (order.orderType == OrderType.TAKE_PROFIT) {
            if (marketPrice < order.triggerPrice) revert TriggerConditionNotMet(order.id);
        }
    }

    function _computeSettlement(Order memory buy, Order memory sell, uint256 ts)
        private
        pure
        returns (
            uint256 settlementPrice,
            uint256 executedQuantity,
            uint256 notionalAmount,
            bool buyFilled,
            bool sellFilled
        )
    {
        settlementPrice = PriceCurve.settlementPrice(buy, sell, ts);
        if (settlementPrice == 0) revert ZeroSettlementPrice();

        uint256 buyerAffordableQuantity =
            MathUtils.mulDiv(buy.remainingIn, settlementPrice, MathUtils.RAY);
        executedQuantity =
            buyerAffordableQuantity < sell.remainingIn ? buyerAffordableQuantity : sell.remainingIn;

        // Compute payment from asset
        notionalAmount = MathUtils.mulDiv(executedQuantity, MathUtils.RAY, settlementPrice);

        // Recompute asset from floored payment to ensure consistency
        executedQuantity = MathUtils.mulDiv(notionalAmount, settlementPrice, MathUtils.RAY);

        // If rounding removed the asset amount, the trade is invalid
        if (executedQuantity == 0) revert ZeroAmount();

        buyFilled = (buy.remainingIn - notionalAmount) == 0;
        sellFilled = (sell.remainingIn - executedQuantity) == 0;
    }
}
