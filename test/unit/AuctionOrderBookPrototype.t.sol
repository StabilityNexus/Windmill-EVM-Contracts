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
}
