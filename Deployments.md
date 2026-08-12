# Deployments

This file records all Windmill Exchange contract deployments across networks, including test/beta versions.

## Contract

- **Name**: `WindmillExchange`
- **Source**: [`src/core/WindmillExchange.sol`](src/core/WindmillExchange.sol)
- **Deploy script**: [`script/DeployWindmill.s.sol`](script/DeployWindmill.s.sol)
- **Constructor parameter**: `wethAddress` (WETH token address for the target network)

## Network Legend

- **ETC** — Ethereum Classic
- **ETH** — Ethereum
- **SEP** — Sepolia (testnet)
- **MOR** — Mordor (ETC testnet)
- **POL** — Polygon PoS
- **BSC** — BNB Smart Chain
- **BASE** — Base
- **AVAX** — Avalanche C-Chain

## Deployment Records

| Network | Type | WindmillExchange Address | Constructor `wethAddress` | Deployment Tx | Date |
|---|---|---|---|---|---|
| — | — | *No deployments recorded yet* | — | — | — |

> Deployment targets are pre-configured in `foundry.toml` (`ethereum`, `sepolia`, `base`, `polygon`, etc.). When a new deployment happens, append a row with the verified contract address, the `wethAddress` used, the deployment transaction hash, and the date.

## Procedure

```bash
cp .env.example .env   # set PRIVATE_KEY, WETH_ADDRESS

forge script script/DeployWindmill.s.sol \
  --rpc-url <alias from foundry.toml> \
  --broadcast --verify -vvvv
```

After a successful deployment:

1. Record the address and constructor params in the table above.
2. Verify the contract on the block explorer (`--verify` does this automatically with the correct `ETHERSCAN_API_KEY`).
3. Post the address in `#windmill-exchange` on Discord.

## Security Note

Only deploy from a dedicated, funded deployment key (never a shared/development key). Testnet deployments are encouraged; mainnet deployments must be reviewed by maintainers first.