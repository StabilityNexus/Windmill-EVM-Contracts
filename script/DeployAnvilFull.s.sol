// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { Script, console } from "forge-std/Script.sol";
import { WindmillExchange } from "../src/core/WindmillExchange.sol";
import { MockERC20 } from "../src/mocks/MockERC20.sol";

contract DeployAnvilFull is Script {
    address constant WETH_ADDR = 0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9;
    address constant USDC_ADDR = 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238;

    address constant ACCOUNT0 = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address constant ACCOUNT1 = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;

    function run() external returns (WindmillExchange exchange) {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerKey);

        // Deploy template Mock tokens
        MockERC20 wethMock = new MockERC20("Wrapped Ether", "WETH", 18);
        MockERC20 usdcMock = new MockERC20("USD Coin", "USDC", 6);

        // Etch contract bytecode onto exact target addresses
        vm.etch(WETH_ADDR, address(wethMock).code);
        vm.etch(USDC_ADDR, address(usdcMock).code);

        // Mint balances to test accounts
        MockERC20(WETH_ADDR).mint(ACCOUNT0, 1_000_000 * 1e18);
        MockERC20(WETH_ADDR).mint(ACCOUNT1, 1_000_000 * 1e18);

        MockERC20(USDC_ADDR).mint(ACCOUNT0, 1_000_000 * 1e6);
        MockERC20(USDC_ADDR).mint(ACCOUNT1, 1_000_000 * 1e6);

        // Deploy WindmillExchange
        exchange = new WindmillExchange(WETH_ADDR);

        vm.stopBroadcast();

        console.log("Deployed WETH Mock at:", WETH_ADDR);
        console.log("Deployed USDC Mock at:", USDC_ADDR);
        console.log("WindmillExchange deployed at:", address(exchange));
    }
}
