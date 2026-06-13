// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { Test } from "forge-std/Test.sol";
import { WindmillExchange } from "../src/core/WindmillExchange.sol";
import { Order } from "../src/types/OrderTypes.sol";
import {
    ZeroAddress,
    SameToken,
    ZeroAmount,
    ZeroStartPrice,
    InvalidExpiry,
    InvalidPriceBounds,
    SlopeOverflow,
    NotMaker,
    OrderInactive,
    OrderExpired,
    SelfMatch,
    OrdersNotMatchable,
    PairMismatch,
    ZeroSettlementPrice,
    UnsupportedTokenBehavior,
    NotOwner,
    ExchangePaused,
    InvalidProtocolFee,
    MismatchedValue,
    NativeEthNotSupported,
    EthTransferFailed
} from "../src/core/WindmillExchange.sol";

contract MockERC20 {
    string public name;
    string public symbol;
    uint8 public constant decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
        totalSupply += amount;
        emit Transfer(address(0), to, amount);
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        require(balanceOf[msg.sender] >= amount, "insufficient");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(balanceOf[from] >= amount, "insufficient");
        if (allowance[from][msg.sender] != type(uint256).max) {
            require(allowance[from][msg.sender] >= amount, "allowance");
            allowance[from][msg.sender] -= amount;
        }
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
}

contract FeeToken {
    function transferFrom(address, address, uint256) external pure returns (bool) {
        return true;
    }

    function balanceOf(address) external pure returns (uint256) {
        return 0;
    }
}

contract MockWETH is MockERC20 {
    constructor() MockERC20("Wrapped Ether", "WETH") {}

    fallback() external payable {
        deposit();
    }

    receive() external payable {
        deposit();
    }

    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
        totalSupply += msg.value;
        emit Transfer(address(0), msg.sender, msg.value);
    }

    function withdraw(uint256 amount) public {
        require(balanceOf[msg.sender] >= amount, "insufficient balance");
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "ETH transfer failed");
    }
}

contract WindmillExchangeTest is Test {
    uint256 internal constant RAY = 1e27;

    WindmillExchange internal exchange;
    MockERC20 internal tokenA;
    MockERC20 internal tokenB;
    MockWETH internal weth;

    address internal alice = makeAddr("alice");
    address internal bob = makeAddr("bob");

    function setUp() public {
        weth = new MockWETH();
        exchange = new WindmillExchange(address(weth));
        tokenA = new MockERC20("TokenA", "TKNA");
        tokenB = new MockERC20("TokenB", "TKNB");

        tokenA.mint(alice, 1_000_000 ether);
        tokenB.mint(bob, 1_000_000 ether);
        weth.mint(alice, 1_000_000 ether);
        deal(alice, 1_000_000 ether);
        deal(bob, 1_000_000 ether);

        vm.prank(alice);
        tokenA.approve(address(exchange), type(uint256).max);
        vm.prank(alice);
        tokenB.approve(address(exchange), type(uint256).max);
        vm.prank(alice);
        weth.approve(address(exchange), type(uint256).max);
        vm.prank(bob);
        tokenA.approve(address(exchange), type(uint256).max);
        vm.prank(bob);
        tokenB.approve(address(exchange), type(uint256).max);
        vm.prank(bob);
        weth.approve(address(exchange), type(uint256).max);
    }

    // Helpers

    /// @dev Alice buys tokenB with tokenA.  tokenIn=tokenA, tokenOut=tokenB.
    function _createBuyOrder(
        address maker,
        uint256 amountIn,
        uint256 startPrice,
        int256 slope,
        uint256 expiry
    ) internal returns (uint256) {
        vm.prank(maker);
        return exchange.createOrder(
            address(tokenA), address(tokenB), amountIn, startPrice, slope, 0, 0, expiry, true
        );
    }

    /// @dev Bob sells tokenB for tokenA.  tokenIn=tokenB, tokenOut=tokenA.
    function _createSellOrder(
        address maker,
        uint256 amountIn,
        uint256 startPrice,
        int256 slope,
        uint256 expiry
    ) internal returns (uint256) {
        vm.prank(maker);
        return exchange.createOrder(
            address(tokenB), address(tokenA), amountIn, startPrice, slope, 0, 0, expiry, false
        );
    }

    // createOrder — success

    function test_createBuyOrder_success() public {
        uint256 amount = 1000 ether;
        uint256 startPrice = 2 * RAY;

        vm.expectEmit(true, true, true, true);
        emit WindmillExchange.OrderCreated(1, alice, address(tokenA), address(tokenB), amount, true);

        uint256 id = _createBuyOrder(alice, amount, startPrice, 0, 0);

        assertEq(id, 1);

        Order memory o = exchange.getOrder(id);
        assertEq(o.maker, alice);
        assertEq(o.tokenIn, address(tokenA));
        assertEq(o.tokenOut, address(tokenB));
        assertEq(o.amountIn, amount);
        assertEq(o.remainingIn, amount);
        assertEq(o.startPrice, startPrice);
        assertTrue(o.isBuy);
        assertTrue(o.active);

        assertEq(tokenA.balanceOf(address(exchange)), amount);
        assertEq(tokenA.balanceOf(alice), 1_000_000 ether - amount);
    }

    function test_createSellOrder_success() public {
        uint256 amount = 500 ether;
        uint256 id = _createSellOrder(bob, amount, 2 * RAY, 0, 0);

        Order memory o = exchange.getOrder(id);
        assertFalse(o.isBuy);
        assertEq(o.tokenIn, address(tokenB));
        assertEq(o.tokenOut, address(tokenA));
        assertEq(tokenB.balanceOf(address(exchange)), amount);
    }

    function test_createOrder_withExpiry() public {
        uint256 expiry = block.timestamp + 1 days;
        uint256 id = _createBuyOrder(alice, 100 ether, RAY, 0, expiry);
        assertEq(exchange.getOrder(id).expiry, expiry);
    }

    function test_createOrder_withSlope() public {
        int256 slope = int256(RAY / 1000);
        uint256 id = _createBuyOrder(alice, 100 ether, RAY, slope, 0);
        assertEq(exchange.getOrder(id).slope, slope);
    }

    function test_ordersByPair_registered() public {
        _createBuyOrder(alice, 100 ether, RAY, 0, 0);
        _createSellOrder(bob, 100 ether, RAY, 0, 0);
        assertEq(
            exchange.getOrdersByPair(address(tokenA), address(tokenB), 0, type(uint256).max).length,
            2
        );
    }

    // createOrder — reverts

    function test_createOrder_revert_zeroTokenIn() public {
        vm.prank(alice);
        vm.expectRevert(ZeroAddress.selector);
        exchange.createOrder(address(0), address(tokenB), 100 ether, RAY, 0, 0, 0, 0, true);
    }

    function test_createOrder_revert_zeroTokenOut() public {
        vm.prank(alice);
        vm.expectRevert(ZeroAddress.selector);
        exchange.createOrder(address(tokenA), address(0), 100 ether, RAY, 0, 0, 0, 0, true);
    }

    function test_createOrder_revert_sameToken() public {
        vm.prank(alice);
        vm.expectRevert(SameToken.selector);
        exchange.createOrder(address(tokenA), address(tokenA), 100 ether, RAY, 0, 0, 0, 0, true);
    }

    function test_createOrder_revert_zeroAmount() public {
        vm.prank(alice);
        vm.expectRevert(ZeroAmount.selector);
        exchange.createOrder(address(tokenA), address(tokenB), 0, RAY, 0, 0, 0, 0, true);
    }

    function test_createOrder_revert_zeroStartPrice() public {
        vm.prank(alice);
        vm.expectRevert(ZeroStartPrice.selector);
        exchange.createOrder(address(tokenA), address(tokenB), 100 ether, 0, 0, 0, 0, 0, true);
    }

    function test_createOrder_revert_expiryInPast() public {
        vm.warp(1000);
        vm.prank(alice);
        vm.expectRevert(InvalidExpiry.selector);
        exchange.createOrder(address(tokenA), address(tokenB), 100 ether, RAY, 0, 0, 0, 999, true);
    }

    function test_createOrder_revert_slopeOverflow() public {
        vm.prank(alice);
        vm.expectRevert(SlopeOverflow.selector);
        exchange.createOrder(
            address(tokenA), address(tokenB), 100 ether, RAY, type(int128).max, 0, 0, 0, true
        );
    }

    function test_createOrder_revert_invalidPriceBounds() public {
        vm.prank(alice);
        vm.expectRevert(InvalidPriceBounds.selector);
        exchange.createOrder(
            address(tokenA), address(tokenB), 100 ether, RAY, 0, 2 * RAY, RAY, 0, true
        );
    }

    // cancelOrder

    function test_cancelOrder_success() public {
        uint256 amount = 200 ether;
        uint256 id = _createBuyOrder(alice, amount, RAY, 0, 0);
        uint256 balBefore = tokenA.balanceOf(alice);

        vm.expectEmit(true, true, false, true);
        emit WindmillExchange.OrderCancelled(id, alice, amount);

        vm.prank(alice);
        exchange.cancelOrder(id);

        assertFalse(exchange.getOrder(id).active);
        assertEq(tokenA.balanceOf(alice), balBefore + amount);
        assertEq(
            exchange.getOrdersByPair(address(tokenA), address(tokenB), 0, type(uint256).max).length,
            0
        );
    }

    function test_cancelOrder_revert_notMaker() public {
        uint256 id = _createBuyOrder(alice, 100 ether, RAY, 0, 0);
        vm.prank(bob);
        vm.expectRevert(NotMaker.selector);
        exchange.cancelOrder(id);
    }

    function test_cancelOrder_revert_alreadyInactive() public {
        uint256 id = _createBuyOrder(alice, 100 ether, RAY, 0, 0);
        vm.prank(alice);
        exchange.cancelOrder(id);
        vm.prank(alice);
        vm.expectRevert(OrderInactive.selector);
        exchange.cancelOrder(id);
    }

    // matchOrders — success (full fill)

    /// @dev Equal amounts at same price → both orders fully filled.
    ///      buyPrice == sellPrice → hasCrossed == true, settlementPrice == startPrice.
    ///      When an order is fully filled, _deactivateOrder is called (not _updateRemainingIn),
    ///      so `remainingIn` in storage is unchanged — test checks active==false instead.
    function test_matchOrders_success_fullFill() public {
        uint256 price = RAY; // 1 tokenA per tokenB
        uint256 amount = 100 ether;

        // At price = 1 RAY, 100 tokenA buys exactly 100 tokenB.
        uint256 buyId = _createBuyOrder(alice, amount, price, 0, 0); // pays tokenA
        uint256 sellId = _createSellOrder(bob, amount, price, 0, 0); // pays tokenB

        uint256 aliceTokenBBefore = tokenB.balanceOf(alice);
        uint256 bobTokenABefore = tokenA.balanceOf(bob);

        exchange.matchOrders(buyId, sellId, block.timestamp + 1);

        // Both orders should be deactivated (fully filled)
        assertFalse(exchange.getOrder(buyId).active, "buy should be inactive");
        assertFalse(exchange.getOrder(sellId).active, "sell should be inactive");

        // Alice should have received tokenB (filledAsset from sell order)
        assertGt(tokenB.balanceOf(alice), aliceTokenBBefore, "alice should receive tokenB");
        // Bob should have received tokenA (paymentOwed from buy order)
        assertGt(tokenA.balanceOf(bob), bobTokenABefore, "bob should receive tokenA");

        // Pair should have no active orders
        assertEq(
            exchange.getOrdersByPair(address(tokenA), address(tokenB), 0, type(uint256).max).length,
            0
        );
    }

    // matchOrders — partial fills

    /// @dev Buy order is smaller than sell order → buy fully fills, sell is partial.
    function test_matchOrders_partialFill_buySmaller() public {
        uint256 price = RAY;
        uint256 buyAmt = 50 ether; // buyer deposits 50 tokenA
        uint256 sellAmt = 100 ether; // seller deposits 100 tokenB

        uint256 buyId = _createBuyOrder(alice, buyAmt, price, 0, 0);
        uint256 sellId = _createSellOrder(bob, sellAmt, price, 0, 0);

        exchange.matchOrders(buyId, sellId, block.timestamp + 1);

        Order memory buyOrder = exchange.getOrder(buyId);
        Order memory sellOrder = exchange.getOrder(sellId);

        // Buy fully consumed — deactivated (remainingIn in storage is unchanged;
        // _updateRemainingIn is only called for partial fills)
        assertFalse(buyOrder.active, "buy should be inactive after full fill");

        // Sell still active with reduced remaining
        assertTrue(sellOrder.active, "sell should still be active");
        assertLt(sellOrder.remainingIn, sellAmt, "sell.remainingIn should have decreased");
        assertGt(sellOrder.remainingIn, 0, "sell.remainingIn should not be 0 yet");

        // Alice received tokenB
        assertGt(tokenB.balanceOf(alice), 0, "alice should receive some tokenB");
        // Bob received tokenA
        assertGt(tokenA.balanceOf(bob), 0, "bob should receive some tokenA");
    }

    /// @dev Sell order is smaller than buy order → sell fully fills, buy is partial.
    ///      When fully filled, _deactivateOrder is called but _updateRemainingIn is NOT.
    function test_matchOrders_partialFill_sellSmaller() public {
        uint256 price = RAY;
        uint256 buyAmt = 100 ether; // buyer deposits 100 tokenA
        uint256 sellAmt = 40 ether; // seller deposits 40 tokenB

        uint256 buyId = _createBuyOrder(alice, buyAmt, price, 0, 0);
        uint256 sellId = _createSellOrder(bob, sellAmt, price, 0, 0);

        exchange.matchOrders(buyId, sellId, block.timestamp + 1);

        Order memory buyOrder = exchange.getOrder(buyId);
        Order memory sellOrder = exchange.getOrder(sellId);

        // Sell fully consumed — deactivated
        assertFalse(sellOrder.active, "sell should be inactive after full fill");

        // Buy still active with reduced remaining
        assertTrue(buyOrder.active, "buy should still be active");
        assertLt(buyOrder.remainingIn, buyAmt, "buy.remainingIn should have decreased");
        assertGt(buyOrder.remainingIn, 0, "buy.remainingIn should not be 0 yet");
    }

    function test_matchOrders_revert_expired() public {
        vm.warp(1000);
        uint256 expiry = 1500;
        uint256 price = RAY;

        uint256 buyId = _createBuyOrder(alice, 100 ether, price, 0, expiry);
        uint256 sellId = _createSellOrder(bob, 100 ether, price, 0, 0);

        // Advance past expiry
        vm.warp(expiry + 1);
        vm.expectRevert(OrderExpired.selector);
        exchange.matchOrders(buyId, sellId, block.timestamp + 1);
    }

    function test_matchOrders_revert_selfMatch() public {
        // Give alice tokenB as well so she can create both sides
        tokenB.mint(alice, 100 ether);
        vm.prank(alice);
        tokenB.approve(address(exchange), type(uint256).max);

        uint256 price = RAY;
        uint256 buyId = _createBuyOrder(alice, 100 ether, price, 0, 0);

        // Alice creates the sell order too
        vm.prank(alice);
        uint256 sellId = exchange.createOrder(
            address(tokenB), address(tokenA), 100 ether, price, 0, 0, 0, 0, false
        );

        vm.expectRevert(SelfMatch.selector);
        exchange.matchOrders(buyId, sellId, block.timestamp + 1);
    }

    function test_matchOrders_revert_noCross() public {
        // buyPrice (0.5 RAY) < sellPrice (2 RAY) → no crossing
        uint256 buyId = _createBuyOrder(alice, 100 ether, RAY / 2, 0, 0);
        uint256 sellId = _createSellOrder(bob, 100 ether, RAY * 2, 0, 0);

        vm.expectRevert(OrdersNotMatchable.selector);
        exchange.matchOrders(buyId, sellId, block.timestamp + 1);
    }

    function test_matchOrders_revert_pairMismatch_wrongIsBuy() public {
        // A buy order matched against another buy order (sell.isBuy=true) triggers PairMismatch.
        uint256 buyId = _createBuyOrder(alice, 100 ether, RAY, 0, 0);

        // Bob creates another buy-side order (isBuy=true) to act as the "sell" argument
        tokenA.mint(bob, 100 ether);
        vm.prank(bob);
        tokenA.approve(address(exchange), type(uint256).max);
        vm.prank(bob);
        uint256 wrongSellId = exchange.createOrder(
            address(tokenA), address(tokenB), 100 ether, RAY, 0, 0, 0, 0, true
        );

        vm.expectRevert(PairMismatch.selector);
        exchange.matchOrders(buyId, wrongSellId, block.timestamp + 1);
    }

    function test_matchOrders_revert_pairMismatch_differentTokens() public {
        // Introduce a third token to create a genuine pair mismatch
        MockERC20 tokenC = new MockERC20("TokenC", "TKNC");
        tokenC.mint(bob, 100 ether);
        vm.prank(bob);
        tokenC.approve(address(exchange), type(uint256).max);

        uint256 buyId = _createBuyOrder(alice, 100 ether, RAY, 0, 0);

        // Sell order for tokenC→tokenA instead of tokenB→tokenA
        vm.prank(bob);
        uint256 sellId = exchange.createOrder(
            address(tokenC), address(tokenA), 100 ether, RAY, 0, 0, 0, 0, false
        );

        vm.expectRevert(PairMismatch.selector);
        exchange.matchOrders(buyId, sellId, block.timestamp + 1);
    }

    function test_currentPrice_flatOrder_returnsStartPrice() public {
        uint256 startPrice = 3 * RAY;
        uint256 id = _createBuyOrder(alice, 100 ether, startPrice, 0, 0);

        // With slope=0, price should always equal startPrice regardless of timestamp
        assertEq(exchange.currentPrice(id, block.timestamp), startPrice);
        assertEq(exchange.currentPrice(id, block.timestamp + 1 days), startPrice);
    }

    function test_currentPrice_descendingSlope_decreasesOverTime() public {
        uint256 startPrice = 4 * RAY;
        int256 slope = -int256(RAY / 1000); // price decreases 1e24 per second

        uint256 id = _createBuyOrder(alice, 100 ether, startPrice, slope, 0);
        uint256 t0 = block.timestamp;

        uint256 priceNow = exchange.currentPrice(id, t0);
        uint256 priceLater = exchange.currentPrice(id, t0 + 1000);

        assertEq(priceNow, startPrice);
        assertLt(priceLater, priceNow, "price should decrease over time with negative slope");
    }

    function test_currentPrice_afterFullMatch_orderInactive() public {
        uint256 price = RAY;
        uint256 buyId = _createBuyOrder(alice, 100 ether, price, 0, 0);
        uint256 sellId = _createSellOrder(bob, 100 ether, price, 0, 0);

        exchange.matchOrders(buyId, sellId, block.timestamp + 1);

        // Order is inactive but getOrder still allows reading; price is still computable
        Order memory o = exchange.getOrder(buyId);
        assertFalse(o.active);
        // currentPrice still returns a value based on stored params (no revert)
        assertEq(exchange.currentPrice(buyId, block.timestamp), price);
    }

    function testFuzz_escrow(uint96 amount) public {
        vm.assume(amount > 0);
        tokenA.mint(alice, amount);
        uint256 id = _createBuyOrder(alice, amount, RAY, 0, 0);
        assertEq(exchange.getOrder(id).remainingIn, amount);
    }

    function test_pause_unpause() public {
        vm.prank(bob);
        vm.expectRevert(NotOwner.selector);
        exchange.pause();

        exchange.pause();
        assertTrue(exchange.paused());

        vm.expectRevert(ExchangePaused.selector);
        exchange.createOrder(address(tokenA), address(tokenB), 100 ether, RAY, 0, 0, 0, 0, true);

        exchange.unpause();
        assertFalse(exchange.paused());
        _createBuyOrder(alice, 100 ether, RAY, 0, 0);
    }

    function test_totalOrders() public {
        assertEq(exchange.totalOrders(), 0);
        _createBuyOrder(alice, 100 ether, RAY, 0, 0);
        assertEq(exchange.totalOrders(), 1);
    }

    function test_transferFrom_allowance() public {
        vm.prank(alice);
        tokenA.approve(address(exchange), 100 ether);

        vm.prank(alice);
        exchange.createOrder(address(tokenA), address(tokenB), 100 ether, RAY, 0, 0, 0, 0, true);
    }

    function test_transferFrom_insufficientAllowance() public {
        vm.prank(alice);
        tokenA.approve(address(exchange), 50 ether);

        vm.prank(alice);
        vm.expectRevert();
        exchange.createOrder(address(tokenA), address(tokenB), 100 ether, RAY, 0, 0, 0, 0, true);
    }

    function test_createOrder_unsupportedTokenBehavior() public {
        FeeToken badToken = new FeeToken();
        vm.prank(alice);
        vm.expectRevert(UnsupportedTokenBehavior.selector);
        exchange.createOrder(address(badToken), address(tokenB), 100 ether, RAY, 0, 0, 0, 0, true);
    }

    function test_currentPrice_maxPriceClamp() public {
        uint256 startPrice = 100;
        int256 slope = 10;
        uint256 maxPrice = 200;
        vm.prank(alice);
        uint256 id = exchange.createOrder(
            address(tokenA), address(tokenB), 100 ether, startPrice, slope, 0, maxPrice, 0, true
        );
        assertEq(exchange.currentPrice(id, block.timestamp + 20), maxPrice);
    }

    function test_currentPrice_minPriceClamp() public {
        uint256 startPrice = 100;
        int256 slope = -10;
        uint256 minPrice = 50;
        vm.prank(alice);
        uint256 id = exchange.createOrder(
            address(tokenA), address(tokenB), 100 ether, startPrice, slope, minPrice, 0, 0, true
        );
        assertEq(exchange.currentPrice(id, block.timestamp + 10), minPrice);
    }

    function test_ordersByPair_pagination() public {
        _createBuyOrder(alice, 100 ether, RAY, 0, 0);
        _createBuyOrder(alice, 100 ether, RAY, 0, 0);
        _createBuyOrder(alice, 100 ether, RAY, 0, 0);

        uint256[] memory orders = exchange.getOrdersByPair(address(tokenA), address(tokenB), 1, 1);
        assertEq(orders.length, 1);

        orders = exchange.getOrdersByPair(address(tokenA), address(tokenB), 5, 10);
        assertEq(orders.length, 0);
    }

    receive() external payable {}

    // ----------------------------------------------------
    // New Feature Tests: Batch Matching, Native ETH, Protocol Fees, Access & Pausing
    // ----------------------------------------------------

    function test_matchOrdersBatch_buyAgainstMultipleSells() public {
        uint256 price = RAY;
        uint256 buyId = _createBuyOrder(alice, 300 ether, price, 0, 0);

        uint256 sellId1 = _createSellOrder(bob, 100 ether, price, 0, 0);
        uint256 sellId2 = _createSellOrder(bob, 100 ether, price, 0, 0);
        uint256 sellId3 = _createSellOrder(bob, 100 ether, price, 0, 0);

        uint256[] memory counterOrderIds = new uint256[](3);
        counterOrderIds[0] = sellId1;
        counterOrderIds[1] = sellId2;
        counterOrderIds[2] = sellId3;

        uint256 aliceTokenBBefore = tokenB.balanceOf(alice);
        uint256 bobTokenABefore = tokenA.balanceOf(bob);

        exchange.matchOrdersBatch(buyId, counterOrderIds, block.timestamp + 1);

        assertFalse(exchange.getOrder(buyId).active);
        assertFalse(exchange.getOrder(sellId1).active);
        assertFalse(exchange.getOrder(sellId2).active);
        assertFalse(exchange.getOrder(sellId3).active);

        assertEq(tokenB.balanceOf(alice) - aliceTokenBBefore, 300 ether);
        assertEq(tokenA.balanceOf(bob) - bobTokenABefore, 300 ether - 0.3 ether);
    }

    function test_matchOrdersBatch_sellAgainstMultipleBuys() public {
        uint256 price = RAY;
        uint256 sellId = _createSellOrder(bob, 250 ether, price, 0, 0);

        uint256 buyId1 = _createBuyOrder(alice, 100 ether, price, 0, 0);
        uint256 buyId2 = _createBuyOrder(alice, 100 ether, price, 0, 0);
        uint256 buyId3 = _createBuyOrder(alice, 100 ether, price, 0, 0);

        uint256[] memory counterOrderIds = new uint256[](3);
        counterOrderIds[0] = buyId1;
        counterOrderIds[1] = buyId2;
        counterOrderIds[2] = buyId3;

        exchange.matchOrdersBatch(sellId, counterOrderIds, block.timestamp + 1);

        assertFalse(exchange.getOrder(sellId).active);
        assertFalse(exchange.getOrder(buyId1).active);
        assertFalse(exchange.getOrder(buyId2).active);
        assertTrue(exchange.getOrder(buyId3).active);
        assertEq(exchange.getOrder(buyId3).remainingIn, 50 ether);
    }

    function test_nativeETH_wrapOnDeposit() public {
        uint256 startBal = alice.balance;
        vm.prank(alice);
        uint256 id = exchange.createOrder{value: 100 ether}(
            address(weth), address(tokenB), 100 ether, RAY, 0, 0, 0, 0, true
        );

        assertEq(alice.balance, startBal - 100 ether);
        assertEq(weth.balanceOf(address(exchange)), 100 ether);
        Order memory o = exchange.getOrder(id);
        assertEq(o.tokenIn, address(weth));
        assertEq(o.remainingIn, 100 ether);
    }

    function test_nativeETH_unwrapOnCancel() public {
        vm.prank(alice);
        uint256 id = exchange.createOrder{value: 100 ether}(
            address(weth), address(tokenB), 100 ether, RAY, 0, 0, 0, 0, true
        );

        uint256 balBefore = alice.balance;
        vm.prank(alice);
        exchange.cancelOrder(id);

        assertEq(alice.balance, balBefore + 100 ether);
        assertEq(weth.balanceOf(address(exchange)), 0);
    }

    function test_nativeETH_unwrapOnSettlement() public {
        vm.prank(alice);
        uint256 buyId = exchange.createOrder{value: 100 ether}(
            address(weth), address(tokenB), 100 ether, RAY, 0, 0, 0, 0, true
        );

        vm.prank(bob);
        uint256 sellId = exchange.createOrder(
            address(tokenB), address(weth), 100 ether, RAY, 0, 0, 0, 0, false
        );

        uint256 aliceBBefore = tokenB.balanceOf(alice);
        uint256 bobETHBefore = bob.balance;
        uint256 keeperETHBefore = address(this).balance;

        exchange.matchOrders(buyId, sellId, block.timestamp + 1);

        assertEq(tokenB.balanceOf(alice) - aliceBBefore, 100 ether);
        assertEq(bob.balance - bobETHBefore, 99.9 ether);
        assertEq(address(this).balance - keeperETHBefore, 0.1 ether);
    }

    function test_nativeETH_revertOnNonWethValue() public {
        vm.prank(alice);
        vm.expectRevert(NativeEthNotSupported.selector);
        exchange.createOrder{value: 10 ether}(
            address(tokenA), address(tokenB), 10 ether, RAY, 0, 0, 0, 0, true
        );
    }

    function test_nativeETH_revertOnMismatchedValue() public {
        vm.prank(alice);
        vm.expectRevert(MismatchedValue.selector);
        exchange.createOrder{value: 5 ether}(
            address(weth), address(tokenB), 10 ether, RAY, 0, 0, 0, 0, true
        );
    }

    function test_protocolFees_setFeeAndRespectCap() public {
        vm.prank(bob);
        vm.expectRevert(NotOwner.selector);
        exchange.setProtocolFee(bob, 100);

        vm.expectRevert(InvalidProtocolFee.selector);
        exchange.setProtocolFee(bob, 501);

        vm.expectRevert(ZeroAddress.selector);
        exchange.setProtocolFee(address(0), 100);

        exchange.setProtocolFee(bob, 200);
        assertEq(exchange.treasury(), bob);
        assertEq(exchange.protocolFeeBps(), 200);
    }

    function test_protocolFees_collectionOnSettlement() public {
        address treasuryAddr = makeAddr("treasury");
        exchange.setProtocolFee(treasuryAddr, 200);

        uint256 buyId = _createBuyOrder(alice, 100 ether, RAY, 0, 0);
        uint256 sellId = _createSellOrder(bob, 100 ether, RAY, 0, 0);

        uint256 treasuryBefore = tokenA.balanceOf(treasuryAddr);
        uint256 bobSellerBefore = tokenA.balanceOf(bob);

        exchange.matchOrders(buyId, sellId, block.timestamp + 1);

        assertEq(tokenA.balanceOf(bob) - bobSellerBefore, 97.9 ether);
        assertEq(tokenA.balanceOf(treasuryAddr) - treasuryBefore, 2 ether);
    }

    function test_cancelOrder_allowedDuringPause() public {
        uint256 id = _createBuyOrder(alice, 100 ether, RAY, 0, 0);

        exchange.pause();
        assertTrue(exchange.paused());

        uint256 balBefore = tokenA.balanceOf(alice);
        vm.prank(alice);
        exchange.cancelOrder(id);

        assertEq(tokenA.balanceOf(alice), balBefore + 100 ether);
        assertFalse(exchange.getOrder(id).active);
    }

    function test_transferOwnership() public {
        vm.prank(bob);
        vm.expectRevert(NotOwner.selector);
        exchange.transferOwnership(bob);

        vm.expectRevert(ZeroAddress.selector);
        exchange.transferOwnership(address(0));

        exchange.transferOwnership(bob);
        assertEq(exchange.owner(), bob);
    }
}
