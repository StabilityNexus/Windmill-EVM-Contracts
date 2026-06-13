// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { Script, console } from "forge-std/Script.sol";
import { WindmillExchange } from "../src/core/WindmillExchange.sol";

contract DeployWindmill is Script {
    function run() external returns (WindmillExchange exchange) {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerKey);

        address wethAddress = vm.envOr("WETH_ADDRESS", address(0xC02aaA39b223FE8D0A0e5C4F27ead9083C756Cc2));
        exchange = new WindmillExchange(wethAddress);

        vm.stopBroadcast();

        console.log("WindmillExchange deployed at:", address(exchange));
    }
}
