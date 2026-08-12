# 🌪️ Windmill Exchange — End-to-End User & Demo Guide

Welcome to **Windmill Exchange**, an advanced on-chain decentralized exchange (DEX) engine featuring configurable dynamic pricing curves, off-chain order discovery, and autonomous keeper bot settlement.

This guide provides a complete step-by-step walkthrough for new users, developers, and evaluators to run, interact with, and test multi-wallet order matching across separate web browsers.

---

## 📐 1. Architecture Overview

| Component | Description | Technologies | Main Location |
| :--- | :--- | :--- | :--- |
| **EVM Smart Contracts** | Core on-chain matching engine, storage, and price curve math | Solidity `^0.8.23`, Foundry | `src/core/WindmillExchange.sol` |
| **WebUI Frontend** | Modern, responsive dApp for trading, orderbook display, and history | Next.js 16 (App Router), React, Tailwind CSS | `Windmill-EVM-WebUI/` |
| **Keeper Bot** | Autonomous background bot that monitors orders and executes `matchOrders` | TypeScript, Node.js, Ethers.js | `Windmill-EVM-Keeper2/` |

---

## ⚙️ 2. Deployed Contract Configuration

| Parameter | Value / Address | Description |
| :--- | :--- | :--- |
| **Target Network** | **Sepolia Testnet** | Ethereum Test Network |
| **Chain ID** | `11155111` (`0xaa36a7`) | Network Chain Identifier |
| **Exchange Contract** | `0x96dce657ba9bd3db2533bbee0b2e2dbf334232d2` | WindmillExchange Core Contract |
| **Test WETH Address** | `0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9` | Wrapped Ether ERC-20 |
| **Test USDC Address** | `0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238` | USD Coin ERC-20 |
| **Localhost Alternative**| Anvil (`http://127.0.0.1:8545`) | Chain ID `31337` for local offline testing |

---

## 🚀 3. Quick Start Command Reference

| Action | Terminal Command | Working Directory | Output / Expected Result |
| :--- | :--- | :--- | :--- |
| **1. WebUI App** | `npm run dev` | `./Windmill-EVM-WebUI` | Web dApp running at `http://localhost:3000` |
| **2. Keeper Bot** | `npm start` | `./Windmill-EVM-Keeper2` | Keeper scanning blocks for matchable orders |
| **3. Contracts (Optional)**| `forge test` | `./` (Root) | Run smart contract test suite |
| **4. Anvil Node (Optional)**| `anvil` | `./` (Root) | Local EVM node on `http://127.0.0.1:8545` |

---

## 💻 4. Step-by-Step Demo Walkthrough

### Step 1: Start the WebUI Server
Open your terminal in the `Windmill-EVM-WebUI` folder and launch the web interface:
```bash
cd Windmill-EVM-WebUI
npm run dev
```
Open **`http://localhost:3000`** in your browser.

---

### Step 2: Setup Two Browsers for Multi-Wallet Testing
To demonstrate real decentralized order matching between two independent users:

1. **Browser 1 (Trader A — Buyer)**:
   - Open standard **Chrome** or **Firefox** at `http://localhost:3000`.
   - Open MetaMask, click the network dropdown, and select **Sepolia Testnet** (`11155111`).
   - Connect **Account 1** (ensure it has Sepolia ETH and test tokens).

2. **Browser 2 (Trader B — Seller)**:
   - Open an **Incognito Window**, a separate Chrome Profile, or **Brave/Firefox** at `http://localhost:3000`.
   - Open MetaMask, select **Sepolia Testnet** (`11155111`).
   - Connect **Account 2**.

---

### Step 3: Start the Keeper Bot Engine
In a separate terminal window, launch the automated settlement bot:
```bash
cd Windmill-EVM-Keeper2
npm start
```
*The keeper bot actively listens for on-chain `OrderCreated` logs and calculates crossing prices using the dynamic price curve algorithm.*

---

### Step 4: Place Orders Across Both Browsers

#### 🛒 Browser 1 — Place BUY Order:
1. Navigate to `http://localhost:3000/dashboard`.
2. Configure the order form:
   - **Type**: `Buy`
   - **Asset Pair**: `WETH / USDC`
   - **Amount**: `1` WETH
   - **Start Price**: `$3000`
   - **Price Slope**: `-0.2` (Dutch Auction decay per second, or `0` for fixed limit order)
3. Click **Place Order**.
4. Confirm **Token Approval** transaction in MetaMask (if first time), then confirm **Order Submission**.
5. Order #1 will appear on-chain and populate in your Active Orders table.

#### 🏷️ Browser 2 — Place SELL Order:
1. Switch to Browser 2 (`http://localhost:3000/dashboard`).
2. Configure the counter-order:
   - **Type**: `Sell`
   - **Asset Pair**: `WETH / USDC`
   - **Amount**: `1` WETH
   - **Start Price**: `$3000` (or lower, e.g. `$2990` to immediately cross the buy price)
3. Click **Place Order** and confirm transactions in MetaMask.
4. Order #2 will register on-chain.

---

### Step 5: Automatic On-Chain Settlement

1. Within **15–30 seconds**, the **Keeper Bot** will detect that Buy Order #1 and Sell Order #2 overlap in price.
2. The Keeper executes `matchOrders(buyOrderId, sellOrderId)` on the `WindmillExchange` contract.
3. On both WebUI dashboards:
   - The active orders will automatically move from **Active Orders** to **Settled History**.
   - Tokens (WETH and USDC) are instantly swapped between Trader A and Trader B on-chain.
   - Settlement logs and transaction hashes are updated live.

---

## 📊 5. Order Parameters Reference Table

| Field Name | Type | Recommended Value | Explanation |
| :--- | :--- | :--- | :--- |
| `orderType` | Enum | `Buy` / `Sell` | Direction of the trade. |
| `tokenIn` | Address | WETH / USDC address | Token locked into contract by the maker. |
| `tokenOut` | Address | USDC / WETH address | Token requested by the maker in return. |
| `amount` | Decimal | e.g. `1.0` | Quantity of `tokenIn` being offered. |
| `startPrice` | Decimal | e.g. `$3000.00` | Initial price per unit in RAY precision ($10^{27}$). |
| `slope` | Decimal | e.g. `-0.2` or `0.0` | Dynamic rate of price change per second. Negative = descending price. |
| `minPrice` / `maxPrice` | Decimal | e.g. `0` | Dynamic price boundary floor/ceiling. |
| `expiry` | Timestamp | Optional (e.g., +24h) | Unix timestamp after which order cannot be matched. |

---

## ❓ 6. Troubleshooting & FAQs

| Error Message / Issue | Root Cause | Solution |
| :--- | :--- | :--- |
| **"Smart contract address or provider not connected on this chain"** | Wallet is connected to wrong chain (e.g. Mainnet/Polygon) or not connected. | Switch MetaMask network to **Sepolia Testnet** (`11155111`) or Localhost Anvil (`31337`). |
| **"Execution reverted: ERC20: transfer amount exceeds allowance"** | ERC-20 token allowance was not granted to exchange contract. | The WebUI auto-prompts for approval. Click approve in MetaMask before submitting order. |
| **"Keeper log: RPC response error"** | Public RPC node rate-limited or offline. | Update `RPC_URL` in `Windmill-EVM-Keeper2/.env` to a reliable Sepolia RPC (e.g. Infura, Alchemy, or PublicNode). |
| **No testnet ETH for gas** | New Sepolia wallet with 0 ETH balance. | Claim testnet ETH from [Sepolia Faucet](https://sepoliafaucet.com) or [Chainlink Faucet](https://faucets.chain.link). |

---

## 🎯 Summary Checklist for Demonstrations

- [x] **WebUI Running**: `http://localhost:3000` accessible.
- [x] **Keeper Running**: Node process listening for events.
- [x] **2 Wallets Connected**: Browser 1 (Buyer) & Browser 2 (Seller) on Sepolia Testnet.
- [x] **Buy Order Submitted**: Verified on-chain via transaction hash.
- [x] **Sell Order Submitted**: Verified on-chain.
- [x] **Match Verified**: Trade settled by Keeper Bot and listed in history table.
