// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {AuctionOrderBookPrototype} from "../../src/AuctionOrderBookPrototype.sol";

contract AuctionOrderBookPrototypeTest is Test {
    AuctionOrderBookPrototype internal book;

    address internal maker = address(0xA11CE);
    address internal taker = address(0xB0B);

    function setUp() public {
        book = new AuctionOrderBookPrototype();
        vm.deal(maker, 1000 ether);
        vm.deal(taker, 1000 ether);
    }


    function test_createOrder_revertsStartPriceOverflow() public {
        uint256 overflowPrice = uint256(type(int256).max) + 1;
        vm.prank(maker);
        vm.expectRevert("startPrice overflows int256");
        book.createOrder(false, 10, overflowPrice, 0, 0, 0);
    }


    function test_createBuyOrder_revertsUnsupported() public {
        vm.prank(maker);
        vm.expectRevert("Buy-side orders not supported");
        book.createOrder{value: 10 * 0.01 ether}(true, 10, 0.01 ether, 0, 0, 0);
    }

    function test_createSellOrder_rejectsEth() public {
        vm.prank(maker);
        vm.expectRevert("Sell order should not send ETH");
        book.createOrder{value: 1}(false, 5, 0.01 ether, 0, 0, 0);
    }

    function test_currentPrice_becomesZeroAfterExpiry() public {
        uint256 startPrice = 0.01 ether;
        uint256 expiry = block.timestamp + 10;
        vm.prank(maker);
        uint256 id = book.createOrder(false, 10, startPrice, 0, 0, expiry);

        vm.warp(expiry + 1);
        assertEq(book.currentPrice(id), 0);
        assertTrue(book.isExpired(id));
    }

    function test_executeOrder_blocksCreatorSelfExecution() public {
        vm.prank(maker);
        uint256 id = book.createOrder(false, 10, 0.01 ether, 0, 0, 0);

        vm.prank(maker);
        vm.expectRevert("Creator cannot execute own order");
        book.executeOrder(id, 1);
    }

    function test_executeSellOrder_requiresExactEth() public {
        vm.prank(maker);
        uint256 id = book.createOrder(false, 10, 0.01 ether, 0, 0, 0);

        // Revert case: wrong ETH amount.
        vm.prank(taker);
        vm.expectRevert("Must pay exact ETH");
        book.executeOrder{value: 0.050000000000000001 ether}(id, 5);

        // Success case: correct ETH amount for 5 units at 0.01 ether/unit.
        uint256 exactCost = 5 * 0.01 ether;
        uint256 makerBefore = maker.balance;
        uint256 takerBefore = taker.balance;

        vm.prank(taker);
        book.executeOrder{value: exactCost}(id, 5);

        // Maker received the ETH.
        assertEq(maker.balance, makerBefore + exactCost);
        // Taker's balance decreased by exactly the cost (gas excluded; vm doesn't charge).
        assertEq(taker.balance, takerBefore - exactCost);
        // Order still active with 5 units remaining.
        AuctionOrderBookPrototype.Order memory o = book.getOrder(id);
        assertEq(o.amount, 5);
        assertTrue(o.active);
    }

    function test_executeBuyOrder_alwaysReverts() public {
        // Buy orders are now rejected at creation; verify the exact revert.
        vm.prank(maker);
        vm.expectRevert("Buy-side orders not supported");
        book.createOrder{value: 40 * 0.01 ether}(true, 40, 0.01 ether, -1e12, 0, 0);
    }

    function test_expireOrder_refundsAndDeactivates() public {
        // Buy orders are now rejected; use a sell order for the expiry path instead.
        vm.prank(maker);
        uint256 id = book.createOrder(false, 10, 0.01 ether, 0, 0, block.timestamp + 5);

        vm.warp(block.timestamp + 6);

        uint256 makerBefore = maker.balance;
        vm.prank(taker);
        book.expireOrder(id);

        AuctionOrderBookPrototype.Order memory o = book.getOrder(id);
        assertFalse(o.active);
        // Sell orders have no ETH escrow; maker balance unchanged.
        assertEq(maker.balance, makerBefore);
        assertEq(book.getActiveOrderCount(), 0);
    }

    function test_pruneOrder_deactivatesAndRemoves() public {
        vm.prank(maker);
        // Sell order with start 0.01 and slope -0.01/sec => price 0 after 1 sec
        uint256 id = book.createOrder(false, 10, 0.01 ether, -0.01 ether, 0, 0);
        
        vm.warp(block.timestamp + 1);
        assertEq(book.currentPrice(id), 0);
        assertFalse(book.isExpired(id));
        
        uint256 countBefore = book.getActiveOrderCount();
        book.pruneOrder(id);
        
        AuctionOrderBookPrototype.Order memory o = book.getOrder(id);
        assertFalse(o.active);
        assertEq(book.getActiveOrderCount(), countBefore - 1);
        
        uint256[] memory activeIds = book.getActiveOrderIds();
        bool found = false;
        for (uint i = 0; i < activeIds.length; i++) {
            if (activeIds[i] == id) found = true;
        }
        assertFalse(found);
    }

    function test_pruneOrder_revertsIfActiveOrHigherPrice() public {
        vm.prank(maker);
        uint256 id = book.createOrder(false, 10, 0.01 ether, 0, 0, 0);
        
        vm.expectRevert("Order still has valid price");
        book.pruneOrder(id);
    }

    function test_pruneOrder_revertsIfInactive() public {
        vm.prank(maker);
        uint256 id = book.createOrder(false, 10, 0.01 ether, 0, 0, 0);
        
        vm.prank(maker);
        book.cancelOrder(id);
        
        vm.expectRevert("Order not active");
        book.pruneOrder(id);
    }

    function test_pruneOrder_revertsOnExpired() public {
        vm.prank(maker);
        uint256 id = book.createOrder(false, 10, 0.01 ether, 0, 0, block.timestamp + 10);
        
        vm.warp(block.timestamp + 11);
        // Before calling pruneOrder, we should check if expireOrder works
        // But the user specifically asked for negative test on pruneOrder for expired
        vm.expectRevert("Use expireOrder for expired orders");
        book.pruneOrder(id);
    }
}
