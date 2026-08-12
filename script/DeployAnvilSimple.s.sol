// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { Script, console } from "forge-std/Script.sol";
import { WindmillExchange } from "../src/core/WindmillExchange.sol";
import { MockERC20 } from "../src/mocks/MockERC20.sol";

contract DeployAnvilSimple is Script {
    function run() external returns (WindmillExchange exchange, MockERC20 weth, MockERC20 usdc) {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerKey);

        weth = new MockERC20("Wrapped Ether", "WETH", 18);
        usdc = new MockERC20("USD Coin", "USDC", 6);

        address account0 = vm.addr(deployerKey);
        weth.mint(account0, 1_000_000 * 1e18);
        usdc.mint(account0, 1_000_000 * 1e6);

        exchange = new WindmillExchange(address(weth));

        vm.stopBroadcast();

        console.log("Mock WETH deployed at:", address(weth));
        console.log("Mock USDC deployed at:", address(usdc));
        console.log("WindmillExchange deployed at:", address(exchange));
    }
}
