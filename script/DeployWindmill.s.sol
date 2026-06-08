// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { Script, console } from "forge-std/Script.sol";
import { WindmillExchange } from "../src/core/WindmillExchange.sol";

contract DeployWindmill is Script {
    function run() external returns (WindmillExchange exchange) {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerKey);

        exchange = new WindmillExchange();

        vm.stopBroadcast();

        console.log("WindmillExchange deployed at:", address(exchange));
    }
}
