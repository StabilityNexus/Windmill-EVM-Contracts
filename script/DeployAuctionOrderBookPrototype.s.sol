// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {AuctionOrderBookPrototype} from "../src/AuctionOrderBookPrototype.sol";

contract DeployAuctionOrderBookPrototype is Script {
    function run() external returns (AuctionOrderBookPrototype deployed) {
        vm.startBroadcast();
        deployed = new AuctionOrderBookPrototype();
        console.log("Deployed AuctionOrderBookPrototype at:", address(deployed));
        vm.stopBroadcast();
    }
}
