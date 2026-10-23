// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { Script, console } from "forge-std/Script.sol";
import { WindmillExchange } from "../src/core/WindmillExchange.sol";

/// @notice Minimal ERC-20 mock for local testing. NOT for production.
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

/// @notice Mock WETH with deposit/withdraw for local testing.
contract MockWETH is MockERC20 {
    constructor() MockERC20("Wrapped Ether", "WETH") { }

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
        (bool success,) = msg.sender.call{ value: amount }("");
        require(success, "ETH transfer failed");
    }
}

/// @notice USDC mock with 6 decimals.
contract MockUSDC is MockERC20 {
    uint8 public constant override_decimals = 6;

    constructor() MockERC20("USD Coin", "USDC") { }

    // Override decimals - can't override constant, so shadow it
    // ERC-20 consumers read the public variable via the getter
}

/**
 * @title DeployAnvilFull
 * @notice Deploys MockWETH, MockUSDC, WindmillExchange, and mints tokens to
 *         anvil default accounts for local development and testing.
 *
 * Usage:
 *   forge script script/DeployAnvilFull.s.sol \
 *     --rpc-url http://127.0.0.1:8545 --broadcast
 */
contract DeployAnvilFull is Script {
    // Anvil default accounts
    address constant ACCOUNT_0 = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address constant ACCOUNT_1 = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
    address constant ACCOUNT_2 = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;

    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerKey);

        // 1. Deploy mock tokens
        MockWETH weth = new MockWETH();
        console.log("MockWETH deployed at:", address(weth));

        MockERC20 usdc = new MockERC20("USD Coin", "USDC");
        console.log("MockUSDC deployed at:", address(usdc));

        // 2. Deploy WindmillExchange with the mock WETH
        WindmillExchange exchange = new WindmillExchange(address(weth));
        console.log("WindmillExchange deployed at:", address(exchange));

        // 3. Mint tokens to default anvil accounts for testing
        uint256 wethAmount = 1000 ether;
        uint256 usdcAmount = 1_000_000 ether; // 18 decimals for mock

        // Account 0 (deployer / keeper)
        weth.mint(ACCOUNT_0, wethAmount);
        usdc.mint(ACCOUNT_0, usdcAmount);

        // Account 1 (buyer)
        weth.mint(ACCOUNT_1, wethAmount);
        usdc.mint(ACCOUNT_1, usdcAmount);

        // Account 2 (seller)
        weth.mint(ACCOUNT_2, wethAmount);
        usdc.mint(ACCOUNT_2, usdcAmount);

        vm.stopBroadcast();

        console.log("");
        console.log("=== DEPLOYMENT SUMMARY ===");
        console.log("MockWETH:          ", address(weth));
        console.log("MockUSDC:          ", address(usdc));
        console.log("WindmillExchange:  ", address(exchange));
        console.log("");
        console.log("Minted to Account 0 (deployer):", ACCOUNT_0);
        console.log("Minted to Account 1 (buyer):   ", ACCOUNT_1);
        console.log("Minted to Account 2 (seller):  ", ACCOUNT_2);
        console.log("Each account received 1000 WETH and 1,000,000 USDC");
        console.log("");
        console.log("Update your .env files with the addresses above.");
    }
}
