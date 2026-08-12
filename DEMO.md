# 🌪️ Windmill Exchange — End-to-End User & Multi-Browser Demo Guide

Welcome to **Windmill Exchange**, an advanced on-chain decentralized exchange (DEX) engine featuring configurable dynamic pricing curves, off-chain order discovery, and autonomous keeper bot settlement.

This document outlines **exact commands**, **separate localhost port configurations**, and **step-by-step instructions** to run two independent web clients (Buyer & Seller) on different localhost URLs and let the Keeper Bot match their orders on-chain.

---

## 📐 1. Architecture Overview

| Component | Description | Technologies | Location |
| :--- | :--- | :--- | :--- |
| **EVM Smart Contracts** | Core on-chain matching engine, storage, and price curve math | Solidity `^0.8.23`, Foundry | `src/core/WindmillExchange.sol` |
| **WebUI Frontend** | Modern dApp interface for trading, orderbook, and history | Next.js 16 (App Router), React, Tailwind CSS | `Windmill-EVM-WebUI/` |
| **Keeper Bot** | Autonomous background bot that monitors orders and executes `matchOrders` | TypeScript, Node.js, Ethers.js | `Windmill-EVM-Keeper2/` |

---

## ⚙️ 2. Deployed Contract Configuration

| Parameter | Sepolia Testnet | Localhost Anvil (Offline Alternative) |
| :--- | :--- | :--- |
| **Network Name** | **Sepolia Testnet** | Anvil Localhost |
| **Chain ID** | `11155111` (`0xaa36a7`) | `31337` (`0x7a69`) |
| **Exchange Contract** | `0x96dce657ba9bd3db2533bbee0b2e2dbf334232d2` | `0x96dce657ba9bd3db2533bbee0b2e2dbf334232d2` |
| **WETH Address** | `0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9` | `0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9` |
| **USDC Address** | `0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238` | `0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238` |

---

## 🚀 3. Command Reference Table (Distinct Localhost Instances)

| Process | Terminal Window | Directory | Command | Target Localhost URL |
| :--- | :--- | :--- | :--- | :--- |
| **WebUI #1 (Buyer)** | **Terminal 1** | `./Windmill-EVM-WebUI` | `npm run dev -- -p 3000` | **`http://localhost:3000`** |
| **WebUI #2 (Seller)** | **Terminal 2** | `./Windmill-EVM-WebUI` | `npm run dev -- -p 3001` | **`http://localhost:3001`** *(or `http://127.0.0.1:3000`)* |
| **Keeper Bot Engine** | **Terminal 3** | `./Windmill-EVM-Keeper2` | `npm start` | Background RPC listener |
| **Anvil Node (Optional)**| **Terminal 4** | `./` (Root) | `anvil` | Local EVM `http://127.0.0.1:8545` |

---

## 🌐 4. Why Use Separate Localhost Instances?

When testing multi-wallet dApp interactions, running two distinct frontend instances ensures:
1. **Isolated Wallet Sessions**: Browser 1 connects Account 1 on Port `3000`, while Browser 2 connects Account 2 on Port `3001`.
2. **Preventing State Collisions**: Avoids Web3 provider cache overrides between two open tabs in the same browser.

---

## 💻 5. Detailed Step-by-Step Walkthrough

### Step 1: Launch WebUI Instance 1 (Port 3000 — Buyer Client)
Open **Terminal 1**:
```bash
cd Windmill-EVM-WebUI
npm run dev -- -p 3000
```
> Server running at: **`http://localhost:3000`**

---

### Step 2: Launch WebUI Instance 2 (Port 3001 — Seller Client)
Open **Terminal 2**:
```bash
cd Windmill-EVM-WebUI
npm run dev -- -p 3001
```
> Server running at: **`http://localhost:3001`**

*(Alternatively, you can also use `http://127.0.0.1:3000` in Browser 2 if running a single server instance).*

---

### Step 3: Launch the Keeper Bot Engine
Open **Terminal 3**:
```bash
cd Windmill-EVM-Keeper2
npm start
```
> Keeper bot actively listening for on-chain `OrderCreated` events and matching orders.

---

### Step 4: Configure Browsers & Connect Wallets

| Client | Browser | Localhost URL | Connected Wallet | Target Network |
| :--- | :--- | :--- | :--- | :--- |
| **Client 1 (Buyer)** | Chrome / Edge | `http://localhost:3000` | MetaMask — **Account 1** | Sepolia (`11155111`) |
| **Client 2 (Seller)** | Incognito / Firefox | `http://localhost:3001` | MetaMask — **Account 2** | Sepolia (`11155111`) |

1. **In Browser 1 (`http://localhost:3000`)**:
   - Click **Connect Wallet** in top right.
   - Select MetaMask **Account 1**.
   - Ensure Network is set to **Sepolia Testnet** (`11155111`).

2. **In Browser 2 (`http://localhost:3001`)**:
   - Click **Connect Wallet** in top right.
   - Select MetaMask **Account 2**.
   - Ensure Network is set to **Sepolia Testnet** (`11155111`).

---

### Step 5: Place Matching Orders Across Browsers

#### 🛒 Browser 1 (Port 3000) — Place BUY Order:
1. Navigate to `http://localhost:3000/dashboard`.
2. Fill out the **Create Order** form:
   - **Order Type**: `Buy`
   - **Asset Pair**: `WETH / USDC`
   - **Amount**: `1` WETH
   - **Start Price**: `$3000`
   - **Price Slope**: `-0.2` (Dutch auction price decay, or `0` for limit order)
3. Click **Place Order**.
4. Confirm **Token Approval** transaction in MetaMask, then confirm **Order Creation**.
5. Order #1 will appear under **Active Orders**.

#### 🏷️ Browser 2 (Port 3001) — Place SELL Order:
1. Navigate to `http://localhost:3001/dashboard`.
2. Fill out the counter-order form:
   - **Order Type**: `Sell`
   - **Asset Pair**: `WETH / USDC`
   - **Amount**: `1` WETH
   - **Start Price**: `$3000` (or `$2990` to cross the spread immediately)
3. Click **Place Order** and confirm in MetaMask.
4. Order #2 will appear under **Active Orders**.

---

### Step 6: Automatic On-Chain Settlement

1. Within **15–30 seconds**, the **Keeper Bot** running in Terminal 3 will detect that Buy Order #1 and Sell Order #2 overlap in price.
2. The Keeper executes `matchOrders(buyOrderId, sellOrderId, deadline)` on the `WindmillExchange` contract.
3. On both WebUI dashboards (`:3000` and `:3001`):
   - Orders move automatically from **Active Orders** to **Settled History**.
   - Tokens (WETH/USDC) swap between Account 1 and Account 2 on-chain.

---

## 📊 6. Order Parameters Table

| Field Name | Type | Recommended Value | Explanation |
| :--- | :--- | :--- | :--- |
| `orderType` | Enum | `Buy` / `Sell` | Direction of the trade. |
| `tokenIn` | Address | WETH / USDC address | Token locked into contract by the maker. |
| `tokenOut` | Address | USDC / WETH address | Token requested by the maker in return. |
| `amount` | Decimal | `1.0` | Quantity of `tokenIn` being offered. |
| `startPrice` | Decimal | `$3000.00` | Initial price per unit in RAY precision ($10^{27}$). |
| `slope` | Decimal | `-0.2` or `0.0` | Dynamic rate of price change per second. |
| `minPrice` / `maxPrice` | Decimal | `0` | Dynamic price boundary floor/ceiling. |

---

## ❓ 7. Troubleshooting & FAQs

| Issue / Error | Root Cause | Solution |
| :--- | :--- | :--- |
| **"Port 3000 is already in use"** | Another process is using port 3000. | Next.js will automatically prompt to use another port, or pass `-p 3001` explicitly. |
| **"Smart contract address or provider not connected on this chain"** | Wallet is connected to unsupported chain. | Switch MetaMask network to **Sepolia Testnet** (`11155111`) or Localhost Anvil (`31337`). |
| **"Execution reverted: ERC20: transfer amount exceeds allowance"** | ERC-20 token allowance was not granted. | Click approve in MetaMask before submitting order. |
| **Keeper bot not matching** | Price curves do not cross yet. | Ensure Sell Start Price <= Buy Current Price, or set slope = `0`. |

---

## 🎯 Verification Checklist

- [x] **WebUI Client 1 Running**: `http://localhost:3000` (Port 3000)
- [x] **WebUI Client 2 Running**: `http://localhost:3001` (Port 3001)
- [x] **Keeper Bot Active**: Listening to Sepolia / Anvil network
- [x] **Buy Order Submitted**: Tx confirmed on Client 1
- [x] **Sell Order Submitted**: Tx confirmed on Client 2
- [x] **On-Chain Settlement Complete**: Matched by Keeper Bot
