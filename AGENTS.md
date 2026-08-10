# AGENTS.md

Guidance for AI coding agents working in the **Windmill-EVM-Contracts** repository.

## Project overview

Core Solidity contracts for Windmill Exchange — an on-chain order matching engine with configurable dynamic pricing curves, matched by autonomous keeper bots. Built with Foundry (`forge`, `cast`, `anvil`).

## Repository layout

- `src/core/WindmillExchange.sol` — main exchange contract (matching, orders, pairs).
- `src/interfaces/` — `IWindmillExchange.sol`, `IERC20.sol`.
- `src/libraries/` — `MathUtils.sol`, `PriceCurve.sol`, `TokenTransfer.sol`.
- `src/storage/` — `OrderStorage.sol`, `PairStorage.sol`.
- `script/DeployWindmill.s.sol` — deployment script (uses `PRIVATE_KEY`, `WETH_ADDRESS` env vars).
- `test/WindmillExchange.t.sol` — test suite.

## Development workflow

```bash
forge install           # install submodule deps
forge build             # compile
forge test -vv          # run tests verbosely
forge fmt --check       # format check
forge coverage          # coverage report
forge snapshot          # update gas snapshot
```

CI runs format check, build, tests, coverage, Slither (static analysis), gas-snapshot regression, and nightly fuzz. Match the `.github/workflows/*` checks locally before finishing.

## Conventions

- Solidity `^0.8.23`, EVM `paris` (see `foundry.toml`).
- Run `forge fmt` before committing; keep the builder's `[fmt]` settings (`line_length = 100`, etc.).
- NatSpec required on public/external functions. Prefer custom errors over `require` strings.
- New logic requires new tests in `test/WindmillExchange.t.sol`; update the gas snapshot if gas-sensitive paths change.
- No magic constants — configuration lives in `foundry.toml` / `.env`.
- Never commit `.env` contents, private keys, or mainnet deployment keys. `.env.example` is the only committed template.
- When changing deployment behavior, update `Deployments.md` (addresses + constructor params).

## Environment

Copy `.env.example` to `.env` for deployment-related local work. Public RPC or a local `anvil` node is sufficient for tests.

## Communication

All project communication happens on Discord (`#windmill-exchange`). GitHub is for code only. Mention AI usage in PR descriptions when applicable. Report vulnerabilities privately (Discord/Telegram), never in public issues.