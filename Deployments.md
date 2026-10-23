# Deployments

All deployments of contracts in this repo, including test/beta versions, are documented in this file.
This file lists the addresses of the contracts that have been deployed as well as the constructor parameters that have been used.

| Network | Network ID | Version | Contract | Address | Constructor Parameters | Comments |
|---|---:|---|---|---|---|---|
| Sepolia (Testnet) | 11155111 | v0.0.1 | `WindmillExchange` | `0x96dce657ba9bd3db2533bbee0b2e2dbf334232d2` | `wethAddress = 0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9` | Deployed via `DeployWindmill.s.sol` |

---
**Note to Developers:** After making a new deployment, please:
1. create a git tag for the deployed version;
2. add a new row to the table above with the details of the deployment.
