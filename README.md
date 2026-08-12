<!-- Don't delete it -->
<div name="readme-top"></div>

<!-- Organization Logo -->
<div align="center" style="display: flex; align-items: center; justify-content: center; gap: 16px;">
  <img alt="Stability Nexus" src="public/stability.svg" width="175">
</div>

&nbsp;

<!-- Organization Name -->
<div align="center">

[![Static Badge](https://img.shields.io/badge/Stability_Nexus-Windmill_Exchange-228B22?style=for-the-badge&labelColor=FFC517)](https://stability.nexus/)

</div>

<!-- Organization/Project Social Handles -->
<p align="center">
<!-- Telegram -->
<a href="https://t.me/StabilityNexus">
<img src="https://img.shields.io/badge/Telegram-black?style=flat&logo=telegram&logoColor=white&logoSize=auto&color=24A1DE" alt="Telegram Badge"/></a>
&nbsp;&nbsp;
<!-- X (formerly Twitter) -->
<a href="https://x.com/StabilityNexus">
<img src="https://img.shields.io/twitter/follow/StabilityNexus" alt="X (formerly Twitter) Badge"/></a>
&nbsp;&nbsp;
<!-- Discord -->
<a href="https://discord.gg/YzDKeEfWtS">
<img src="https://img.shields.io/discord/995968619034984528?style=flat&logo=discord&logoColor=white&logoSize=auto&label=Discord&labelColor=5865F2&color=57F287" alt="Discord Badge"/></a>
&nbsp;&nbsp;
<!-- Medium -->
<a href="https://news.stability.nexus/">
  <img src="https://img.shields.io/badge/Medium-black?style=flat&logo=medium&logoColor=black&logoSize=auto&color=white" alt="Medium Badge"></a>
&nbsp;&nbsp;
<!-- LinkedIn -->
<a href="https://linkedin.com/company/stability-nexus">
  <img src="https://img.shields.io/badge/LinkedIn-black?style=flat&logo=LinkedIn&logoColor=white&logoSize=auto&color=0A66C2" alt="LinkedIn Badge"></a>
&nbsp;&nbsp;
<!-- Youtube -->
<a href="https://www.youtube.com/@StabilityNexus">
  <img src="https://img.shields.io/youtube/channel/subscribers/UCZOG4YhFQdlGaLugr_e5BKw?style=flat&logo=youtube&logoColor=white&logoSize=auto&labelColor=FF0000&color=FF0000" alt="Youtube Badge"></a>
</p>

---

<div align="center">
<h1>Windmill Exchange</h1>
</div>

Windmill Exchange is a decentralized on-chain order matching engine with configurable dynamic pricing curves and autonomous keeper matching. 

---

## 🚀 Features

- **Decentralized Matchmaking**: Fully on-chain, transparent, and verifiable financial infrastructure.
- **Dynamic Pricing Curves**: Orders autonomously adjust their prices over time, creating natural market convergence without requiring active participation.
- **Keeper Ecosystem**: Autonomous keepers scan and match compatible orders using the O(N log N) two-pointer sweep algorithm. Run your own keeper node to earn fees.
- **Multi-Chain Native**: Deploy across Ethereum, Polygon, BSC, Base, and more.

---

## Architecture

```text
Windmill-EVM-Contracts/
├── src/
│   └── core/
│       └── WindmillExchange.sol  # Core matching logic contract
├── Windmill-EVM-Keeper2/         # Node.js autonomous keeper matching bot
├── Windmill-EVM-WebUI/           # Next.js user interface
```

---

## Tech Stack

| Layer | Technology |
|---|---|
| Smart Contracts | Solidity `^0.8.x` |
| Framework | [Foundry](https://getfoundry.sh/) (forge, cast, anvil) |
| Libraries | OpenZeppelin |
| Keeper Node | Node.js, ethers.js |
| Web UI | Next.js, React, Tailwind CSS |

---

## 🔗 Repository Links

1. [Main Repository](https://github.com/StabilityNexus/Windmill-EVM-Contracts)

---

## Getting Started

### Prerequisites

| Tool | Version | Install |
|---|---|---|
| `git` | any | [git-scm.com](https://git-scm.com/) |
| `foundryup` | latest | See [getfoundry.sh](https://getfoundry.sh) |
| `forge` / `cast` / `anvil` | latest | run `foundryup` after install |
| `node` | 20+ | [nodejs.org](https://nodejs.org) |

### Environment Setup

```bash
cp .env.example .env
```

Edit `.env` and fill in:

```env
# Required for deployment
PRIVATE_KEY=0x...

# Required for contract verification
ETHERSCAN_API_KEY=...

# Optional: override default public RPCs
RPC_ETHEREUM=https://mainnet.infura.io/v3/YOUR_KEY
RPC_SEPOLIA=https://sepolia.infura.io/v3/YOUR_KEY
```

---

## Usage

### Build Contracts

```bash
forge build
```

### Test Contracts

```bash
# Run all tests
forge test

# Verbose output (shows logs and traces)
forge test -vvv
```

### Run Web UI & Keeper Locally

To run the Web UI interface and the autonomous keeper matching bot together on your laptop/machine:

```powershell
# Setup and launch both the Web UI and Keeper in parallel windows
powershell -ExecutionPolicy Bypass -File .\start_all.ps1
```

This will automatically create configuration templates, install dependencies, and launch the Web UI (on `http://localhost:3000/trade`) and the Keeper bot loop in two separate PowerShell windows.

> [!NOTE]
> Configure your environment variables:
> - Web UI: Fill in `NEXT_PUBLIC_CONTRACT_ADDRESS_SEPOLIA` inside `Windmill-EVM-WebUI/.env.local`.
> - Keeper: Fill in `PRIVATE_KEY` and `CONTRACT_ADDRESS` inside `Windmill-EVM-Keeper2/.env`.

---

## Supported Networks

Pre-configured RPC endpoints in `foundry.toml`.

| Network | Type | Chain ID | 
|---|---|---|---|
| Ethereum | Mainnet | 1 |
| Ethereum Classic | Mainnet | 61 |
| Polygon PoS | Mainnet | 137 | 
| BNB Smart Chain | Mainnet | 56 |
| Base | Mainnet | 8453 | 
| Sepolia | Testnet | 11155111 |
| Mordor (ETC) | Testnet | 63 |

---

## 🙌 Contributing

⭐ Don't forget to star this repository if you find it useful! ⭐

Thank you for considering contributing to this project! Contributions are highly appreciated and welcomed. To ensure smooth collaboration, please refer to our [Contribution Guidelines](./CONTRIBUTING.md).

---

## 📍 License

See the [LICENSE](LICENSE) file for details.

---

## 💪 Thanks To All Contributors

Thanks a lot for spending your time helping Windmill Exchange grow. Keep rocking!

[![Contributors](https://contrib.rocks/image?repo=StabilityNexus/Windmill-EVM-Contracts)](https://github.com/StabilityNexus/Windmill-EVM-Contracts/graphs/contributors)

© 2026 Stability Nexus
