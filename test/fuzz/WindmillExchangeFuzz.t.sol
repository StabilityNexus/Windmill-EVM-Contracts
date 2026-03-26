// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../../src/core/WindmillExchange.sol";
import "../../src/mocks/MockERC20.sol";
import "../../src/libraries/PriceLib.sol";

/// @notice Fuzz + invariant tests for WindmillExchange
/// @dev Run with: forge test --match-path test/fuzz/WindmillExchangeFuzz.t.sol -vvv
contract WindmillExchangeFuzzTest is Test {
    WindmillExchange internal exchange;
    MockERC20       internal tokenA;
    MockERC20       internal tokenB;

    address internal maker  = makeAddr("maker");
    address internal taker  = makeAddr("taker");

    // ---- Setup ---------------------------------------------------------------

    function setUp() public {
        exchange = new WindmillExchange();
        tokenA   = new MockERC20("TokenA", "TKA");
        tokenB   = new MockERC20("TokenB", "TKB");

        tokenA.mint(maker, type(uint128).max);
        tokenB.mint(taker, type(uint128).max);
        tokenA.mint(taker, type(uint128).max);
        tokenB.mint(maker, type(uint128).max);

        vm.prank(maker); tokenA.approve(address(exchange), type(uint256).max);
        vm.prank(maker); tokenB.approve(address(exchange), type(uint256).max);
        vm.prank(taker); tokenA.approve(address(exchange), type(uint256).max);
        vm.prank(taker); tokenB.approve(address(exchange), type(uint256).max);
    }

    // ---- Helpers -------------------------------------------------------------

    function _placeBuy(
        uint256 buyAmt,
        uint256 sellAmt,
        uint256 startP,
        uint256 endP,
        uint256 expiry
    ) internal returns (uint256) {
        vm.prank(maker);
        return exchange.placeOrder(
            address(tokenB), address(tokenA),
            buyAmt, sellAmt,
            startP, int256(-1e15), endP,
            expiry
        );
    }

    function _placeSell(
        uint256 buyAmt,
        uint256 sellAmt,
        uint256 startP,
        uint256 endP,
        uint256 expiry
    ) internal returns (uint256) {
        vm.prank(taker);
        return exchange.placeOrder(
            address(tokenA), address(tokenB),
            buyAmt, sellAmt,
            startP, int256(1e15), endP,
            expiry
        );
    }

    // ---- Fuzz #1: PriceLib BUY never below floor ----------------------------

    /// @notice Proves priceAt(BUY) >= endPrice for all elapsed values.
    function testFuzz_priceLib_buyNeverBelowFloor(
        uint128 startPrice,
        uint64  absSlope,
        uint32  elapsed
    ) public pure {
        // endPrice = half of startPrice to guarantee valid floor < start
        vm.assume(startPrice > 1 && absSlope > 0);
        uint256 endPrice = uint256(startPrice) / 2;
        vm.assume(endPrice > 0 && endPrice < startPrice);

        uint256 p = PriceLib.priceAt(
            startPrice,
            -int256(uint256(absSlope)),
            endPrice,
            0,
            elapsed
        );
        assertGe(p, endPrice, "BUY: price dropped below floor");
        assertLe(p, uint256(startPrice), "BUY: price above start");
    }

    // ---- Fuzz #2: PriceLib SELL never above ceiling -------------------------

    /// @notice Proves priceAt(SELL) <= endPrice for all elapsed values.
    function testFuzz_priceLib_sellNeverAboveCeiling(
        uint128 startPrice,
        uint64  absSlope,
        uint32  elapsed
    ) public pure {
        vm.assume(startPrice > 0 && absSlope > 0);
        uint256 endPrice = uint256(startPrice) * 2; // valid ceiling > start
        vm.assume(endPrice > startPrice && endPrice <= type(uint128).max);

        uint256 p = PriceLib.priceAt(
            startPrice,
            int256(uint256(absSlope)),
            endPrice,
            0,
            elapsed
        );
        assertLe(p, endPrice, "SELL: price exceeded ceiling");
        assertGe(p, uint256(startPrice), "SELL: price below start");
    }

    // ---- Fuzz #3: matchOrders token conservation ----------------------------

    /// @notice exchange never gains tokens out of thin air (no bank-run via matching).
    function testFuzz_matchOrders_tokenConservation(uint32 elapsed) public {
        elapsed = uint32(bound(elapsed, 0, 30 minutes));
        uint256 expiry = block.timestamp + 1 hours;

        uint256 buyId  = _placeBuy(10e18, 10000e18, 1000e18, 800e18, expiry);
        uint256 sellId = _placeSell(10000e18, 10e18, 900e18, 1200e18, expiry);

        vm.warp(block.timestamp + elapsed);

        uint256 exABefore = tokenA.balanceOf(address(exchange));
        uint256 exBBefore = tokenB.balanceOf(address(exchange));

        exchange.matchOrders(buyId, sellId);

        assertLe(tokenA.balanceOf(address(exchange)), exABefore, "exchange gained tokenA");
        assertLe(tokenB.balanceOf(address(exchange)), exBBefore, "exchange gained tokenB");
    }

    // ---- Fuzz #4: pairOrders bounded after cancel (requires FIX #5) ---------

    /// @notice Placing N orders then cancelling all leaves pairOrders empty.
    function testFuzz_pairOrders_emptyAfterCancel(uint8 n) public {
        n = uint8(bound(n, 1, 20));
        bytes32 key = keccak256(abi.encode(address(tokenB), address(tokenA)));
        uint256 expiry = block.timestamp + 1 hours;

        uint256[] memory ids = new uint256[](n);
        for (uint256 i = 0; i < n; i++) {
            ids[i] = _placeBuy(10e18, 1000e18, 1000e18, 800e18, expiry);
        }

        assertEq(exchange.pairOrdersLength(key), n, "wrong initial length");

        for (uint256 i = 0; i < n; i++) {
            vm.prank(maker);
            exchange.cancelOrder(ids[i]);
        }

        assertEq(exchange.pairOrdersLength(key), 0, "pairOrders not cleaned on cancel");
    }

    // ---- Fuzz #5: getOrder remainingBuy+Sell never exceed initial ------------

    /// @notice After a partial or full match, remaining amounts must be <= initial.
    function testFuzz_getOrder_remainingNeverExceedsInitial(uint32 elapsed) public {
        elapsed = uint32(bound(elapsed, 0, 30 minutes));
        uint256 expiry = block.timestamp + 1 hours;

        uint256 ESCROW = 10_000e18;
        uint256 WANT   = 10e18;

        uint256 buyId  = _placeBuy(WANT, ESCROW, 1000e18, 800e18,  expiry);
        uint256 sellId = _placeSell(ESCROW, WANT, 900e18, 1200e18, expiry);

        vm.warp(block.timestamp + elapsed);
        exchange.matchOrders(buyId, sellId);

        (uint256 rb, uint256 rs) = exchange.getRemainingBalances(buyId);
        assertLe(rb, WANT,   "remainingBuy exceeded original");
        assertLe(rs, ESCROW, "remainingSell exceeded original");
    }
}
