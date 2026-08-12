# 🚀 Local Anvil Development & Quick Run Guide

This guide provides the complete step-by-step procedure to run **Windmill Exchange** offline using a local **Anvil** node, pre-funded test accounts, two WebUI clients, and the autonomous Keeper bot.

---

## 📋 Architecture & Terminals Setup

Running the local stack requires **4 separate terminal windows**:

| Process | Terminal | Directory | Command | Target URL / Purpose |
| :--- | :---: | :--- | :--- | :--- |
| **Anvil Node** | **Terminal 1** | `./` (`Windmill-EVM-Contracts`) | `anvil.exe` | Local EVM (`http://127.0.0.1:8545`) |
| **WebUI #1 (Buyer)** | **Terminal 2** | `../Windmill-EVM-WebUI` | `npm run dev -- -p 3000` | **`http://localhost:3000`** |
| **WebUI #2 (Seller)** | **Terminal 3** | `../Windmill-EVM-WebUI` | `npm run dev -- -p 3001` | **`http://localhost:3001`** |
| **Keeper Bot Engine** | **Terminal 4** | `../Windmill-EVM-Keeper2` | `npm start` | Background order monitor |

---

## 🛠️ Step-by-Step Instructions

### Step 1: Start Anvil Local Node
Open **Terminal 1** in the `Windmill-EVM-Contracts` directory:
```cmd
anvil.exe
```
> Keep Terminal 1 open. It listens on `http://127.0.0.1:8545` (Chain ID: `31337`).

---

### Step 2: Deploy Contracts & Seed Test Tokens
Open **Terminal 2** in the `Windmill-EVM-Contracts` directory:
```cmd
set PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
forge.exe script script/DeployAnvilSimple.s.sol --rpc-url http://127.0.0.1:8545 --broadcast
```
> This script automatically:
> 1. Deploys **Mock WETH** (`0x0165878A594ca255338adfa4d48449f69242Eb8F`).
> 2. Deploys **Mock USDC** (`0xa513E6E4b8f2a923D98304ec87F64353C4D5C853`).
> 3. Mints **1,000,000 WETH** and **1,000,000 USDC** to your test account.
> 4. Deploys **WindmillExchange** (`0x610178dA211FEF7D417bC0e6FeD39F05609AD788`).

---

### Step 3: Configure MetaMask Wallet
1. **Add Anvil Network in MetaMask**:
   * **Network Name**: `Anvil Localhost`
   * **RPC URL**: `http://127.0.0.1:8545`
   * **Chain ID**: `31337`
   * **Currency Symbol**: `ETH`

2. **Import Test Accounts into MetaMask** (*Import Account -> Paste Private Key*):
   * **Account 1 (Buyer)**: `0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80`
   * **Account 2 (Seller)**: `0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d`

---

### Step 4: Start WebUI Instance 1 (Buyer Client — Port 3000)
In **Terminal 2** (navigate to the sibling `Windmill-EVM-WebUI` repository):
```cmd
cd ../Windmill-EVM-WebUI
npm run dev -- -p 3000
```
> WebUI active at **`http://localhost:3000`**. Connect MetaMask with **Account 1**.

---

### Step 5: Start WebUI Instance 2 (Seller Client — Port 3001)
Open **Terminal 3** (navigate to the sibling `Windmill-EVM-WebUI` repository):
```cmd
cd ../Windmill-EVM-WebUI
npm run dev -- -p 3001
```
> WebUI active at **`http://localhost:3001`**. Open in Incognito window / 2nd browser and connect MetaMask with **Account 2**.

---

### Step 6: Start the Keeper Bot Engine
Open **Terminal 4** (navigate to the sibling `Windmill-EVM-Keeper2` repository):
```cmd
cd ../Windmill-EVM-Keeper2
npm start
```
> Keeper bot connects to Anvil (`31337`), listening for matching orders every 5 seconds.

---

## ⚡ Instant Test Order Placement & Settlement

### 1. Submit Buy Order (`http://localhost:3000`)
* **Wallet**: Account 1
* **Type**: `Buy Order`
* **Token In**: `WETH` | **Token Out**: `USDC`
* **Amount**: `1` | **Start Price**: `3000` | **Slope**: `0`
* Click **Place Order** -> Confirm Approval & Tx in MetaMask.

### 2. Submit Sell Order (`http://localhost:3001`)
* **Wallet**: Account 2
* **Type**: `Sell Order`
* **Token In**: `USDC` | **Token Out**: `WETH`
* **Amount**: `3000` | **Start Price**: `3000` | **Slope**: `0`
* Click **Place Order** -> Confirm Approval & Tx in MetaMask.

### 3. Automatic Matching
Within **5 seconds**, the Keeper bot in Terminal 4 logs:
`[info] Executing matchOrders for buy order #1 and sell order #2`
Both orders transition to **Settled History** automatically on both WebUI dashboards!

---

## ❓ Troubleshooting

| Issue / Error | Cause | Solution |
| :--- | :--- | :--- |
| **`socket address in use (error 10048)`** | Anvil is already running in background. | Skip running `anvil.exe` again, or run `taskkill /F /IM anvil.exe` to restart. |
| **`Transaction likely to fail`** | Wallet set to Sepolia instead of Anvil. | Switch MetaMask network dropdown to **Anvil Localhost** (`31337`). |
| **`EVM error StackUnderflow`** | Contract bytecode missing on Anvil. | Run `DeployAnvilSimple.s.sol` (Step 2) to deploy contracts and seed test tokens. |
