# 🌪️ Windmill Exchange — End-to-End User & Multi-Browser Demo Guide

Welcome to **Windmill Exchange**, an advanced on-chain decentralized exchange (DEX) engine featuring configurable dynamic pricing curves, off-chain order discovery, and autonomous keeper bot settlement.

This document outlines **exact commands**, **separate localhost port configurations**, **exact copy-paste form values for instant testing**, and **step-by-step instructions** to run two independent web clients (Buyer & Seller) on different localhost URLs and let the Keeper Bot match their orders on-chain.

---

## 📐 1. Architecture Overview

| Component | Description | Technologies | Location |
| :--- | :--- | :--- | :--- |
| **EVM Smart Contracts** | Core on-chain matching engine, storage, and price curve math | Solidity `^0.8.23`, Foundry | `Windmill-EVM-Contracts/` |
| **WebUI Frontend** | Modern dApp interface for trading, orderbook, and history | Next.js 16 (App Router), React, Tailwind CSS | `../Windmill-EVM-WebUI/` (Sibling Repo) |
| **Keeper Bot** | Autonomous background bot that monitors orders and executes `matchOrders` | TypeScript, Node.js, Ethers.js | `../Windmill-EVM-Keeper2/` (Sibling Repo) |

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

## 🚀 3. Quick Start Command Reference (2 Localhost Ports)

| Process | Terminal Window | Directory | Command | Target Localhost URL |
| :--- | :--- | :--- | :--- | :--- |
| **WebUI #1 (Buyer)** | **Terminal 1** | `../Windmill-EVM-WebUI` | `npm run dev -- -p 3000` | **`http://localhost:3000`** |
| **WebUI #2 (Seller)** | **Terminal 2** | `../Windmill-EVM-WebUI` | `npm run dev -- -p 3001` | **`http://localhost:3001`** |
| **Keeper Bot Engine** | **Terminal 3** | `../Windmill-EVM-Keeper2` | `npm start` | Background RPC listener |
| **Anvil Node (Optional)**| **Terminal 4** | `./` (`Windmill-EVM-Contracts`) | `anvil` | Local EVM `http://127.0.0.1:8545` |

---

## 📋 4. Exact Form Input Values (Copy-Paste Test Presets)

Use these exact values when filling out the form on `http://localhost:3000/dashboard` and `http://localhost:3001/dashboard`. No custom calculations needed!

### ⚡ Preset 1: Instant Limit Order Match (Recommended First Test)

| Input Field Name | Browser 1 (Buyer Client — `:3000`) | Browser 2 (Seller Client — `:3001`) | Purpose / Notes |
| :--- | :--- | :--- | :--- |
| **Order Type** | Click **`Buy Order`** | Click **`Sell Order`** | Opposite directions to allow matching |
| **Token In** | `WETH` | `USDC` | Token deposited by trader |
| **Token Out** | `USDC` | `WETH` | Token requested in return |
| **Amount** | `1` | `3000` | Trader 1 buys 1 WETH; Trader 2 offers 3000 USDC |
| **Start Price** | `3000` | `3000` | Matching price floor ($3000/WETH) |
| **Slope (per sec)** | `0` | `0` | `0` = Fixed price limit order |
| **Min Price** | `0` | `0` | `0` = No floor limit |
| **Max Price** | `0` | `0` | `0` = No ceiling limit |
| **Expiry** | *Leave Empty* | *Leave Empty* | Blank = No expiration |

---

### 📉 Preset 2: Dynamic Dutch Auction Match (Decaying Price Curve)

| Input Field Name | Browser 1 (Buyer Client — `:3000`) | Browser 2 (Seller Client — `:3001`) | Purpose / Notes |
| :--- | :--- | :--- | :--- |
| **Order Type** | Click **`Buy Order`** | Click **`Sell Order`** | Dynamic auction match test |
| **Token In** | `WETH` | `USDC` | Deposit asset |
| **Token Out** | `USDC` | `WETH` | Target asset |
| **Amount** | `1` | `3000` | Unit test size |
| **Start Price** | `3200` | `2800` | Buy starts high ($3200), Sell starts low ($2800) |
| **Slope (per sec)** | `-0.2` | `0.1` | Buy price decays down; Sell price ticks up |
| **Min Price** | `2500` | `2000` | Safety bound floor |
| **Max Price** | `3500` | `3500` | Safety bound ceiling |
| **Expiry** | *Leave Empty* | *Leave Empty* | Open until matched |

---

## 💻 5. Step-by-Step Multi-Browser Walkthrough

### Step 1: Launch WebUI Instance 1 (Port 3000 — Buyer Client)
Open **Terminal 1** (navigate to the sibling `Windmill-EVM-WebUI` repository):
```bash
cd ../Windmill-EVM-WebUI
npm run dev -- -p 3000
```
> Server running at **`http://localhost:3000`**

---

### Step 2: Launch WebUI Instance 2 (Port 3001 — Seller Client)
Open **Terminal 2** (navigate to the sibling `Windmill-EVM-WebUI` repository):
```bash
cd ../Windmill-EVM-WebUI
npm run dev -- -p 3001
```
> Server running at **`http://localhost:3001`**

---

### Step 3: Launch the Keeper Bot Engine
Open **Terminal 3** (navigate to the sibling `Windmill-EVM-Keeper2` repository):
```bash
cd ../Windmill-EVM-Keeper2
npm start
```
> Keeper bot active and listening for on-chain `OrderCreated` logs.

---

### Step 4: Connect MetaMask Wallets

1. Open **Browser 1** (`http://localhost:3000`):
   - Click **Connect Wallet** -> Select MetaMask **Account 1** (Sepolia Testnet `11155111`).
2. Open **Browser 2** (`http://localhost:3001` in Incognito or Firefox):
   - Click **Connect Wallet** -> Select MetaMask **Account 2** (Sepolia Testnet `11155111`).

---

### Step 5: Place Orders Using Preset 1 Values

1. **In Browser 1 (`http://localhost:3000/dashboard`)**:
   - Order Type: `Buy Order`
   - Token In: `WETH` | Token Out: `USDC`
   - Amount: `1` | Start Price: `3000` | Slope: `0`
   - Click **Place Order** -> Approve ERC-20 (if prompted) -> Confirm Tx in MetaMask.

2. **In Browser 2 (`http://localhost:3001/dashboard`)**:
   - Order Type: `Sell Order`
   - Token In: `USDC` | Token Out: `WETH`
   - Amount: `3000` | Start Price: `3000` | Slope: `0`
   - Click **Place Order** -> Approve ERC-20 -> Confirm Tx in MetaMask.

---

### Step 6: Automatic Settlement Verification

1. Within **15–30 seconds**, the **Keeper Bot** in Terminal 3 will log:
   `[Keeper] Detected crossing orders #1 and #2. Submitting matchOrders...`
2. Both WebUI dashboards will automatically transition the orders from **Active Orders** to **Settled History**.
3. Balances of Account 1 and Account 2 update on-chain.

---

## ❓ 6. Troubleshooting & FAQs

| Issue / Error | Root Cause | Solution |
| :--- | :--- | :--- |
| **"Smart contract address or provider not connected on this chain"** | Wallet is connected to unsupported network. | Switch MetaMask network to **Sepolia Testnet** (`11155111`) or Localhost Anvil (`31337`). |
| **"Execution reverted: ERC20: transfer amount exceeds allowance"** | ERC-20 token allowance missing. | Allow the WebUI to send the Approval transaction in MetaMask first. |
| **Keeper bot not matching** | Price curves do not cross yet. | Use **Preset 1** (`slope = 0`, `startPrice = 3000` for both) for an instant match. |

---

## 🎯 Demo Summary Checklist

- [x] **Client 1 Running**: `http://localhost:3000`
- [x] **Client 2 Running**: `http://localhost:3001`
- [x] **Keeper Bot Running**: Active on Terminal 3
- [x] **Preset 1 Values Entered**: Buy & Sell orders submitted
- [x] **On-Chain Match Complete**: Settled trade listed in history table
