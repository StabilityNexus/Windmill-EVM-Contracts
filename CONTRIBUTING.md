# Contributing to Windmill EVM Contracts

⭐ First off, thank you for considering contributing to this project! ⭐

We welcome contributions from everyone. By participating in this project, you agree to abide by our Code of Conduct.

## 📢 Discord Communication is Mandatory

**All project communication MUST happen on Discord.**

- Join our [Discord server](https://discord.gg/YzDKeEfWtS) before starting any work.
- Post your PR/issue updates in the project channel, `#windmill-exchange`.
- All discussions, questions, and updates should be on Discord. GitHub is for code only.
- **PRs without Discord updates will not be reviewed or may face delays.**

## Table of Contents

- [How Can I Contribute?](#how-can-i-contribute)
- [Coding with AI](#coding-with-ai)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Pull Request Guidelines](#pull-request-guidelines)
- [Code Style Guidelines](#code-style-guidelines)
- [Security](#security)
- [Community Guidelines](#community-guidelines)
- [Issue Assignment](#issue-assignment)

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates. When creating a bug report, include:

- Clear and descriptive title
- Steps to reproduce the issue
- Expected behavior vs actual behavior
- Environment details (Foundry/forge version, node, chain)

### Suggesting Features

Feature suggestions are welcome! Please:

- Check if the feature has already been suggested
- Provide a clear description of the feature
- Explain why this feature would be useful
- Include examples of how it would work

### Contributing Code

1. **Submit an Issue First**: For features, bugs, or enhancements, create an issue first.
2. **Get Assigned**: Wait to be assigned before starting work (preferable).
3. **Submit Your PR**: Once assigned, create a PR addressing the issue.
4. **Unrelated PRs**: Pull requests unrelated to issues may be closed or take longer to review.

## Coding with AI

We accept the use of AI-powered tools (GitHub Copilot, ChatGPT, Claude, Cursor, etc.) for contributions, whether for code, tests, or documentation.

⚠️ Transparency is required: if you use AI assistance, please mention it in your PR description.

What we expect:

- **Disclose AI usage**: A simple note like "Used GitHub Copilot for autocompletion" or "Generated initial test structure with ChatGPT" is sufficient.
- **Specify the scope**: Indicate which parts of your contribution involved AI assistance.
- **Review AI-generated content**: Ensure you understand and have verified any AI-generated code before submitting. This is especially important for smart contracts.

## Getting Started

### Prerequisites

- Foundry ([getfoundry.sh](https://getfoundry.sh/))
- A code editor with Solidity support

### Setup

1. **Fork the Repository**

   Click the 'Fork' button at the top right of this page.

2. **Clone Your Fork (with submodules)**

   ```bash
   git clone --recurse-submodules https://github.com/YOUR_USERNAME/Windmill-EVM-Contracts.git
   cd Windmill-EVM-Contracts
   git submodule update --init --recursive
   ```

3. **Add Upstream Remote**

   ```bash
   git remote add upstream https://github.com/StabilityNexus/Windmill-EVM-Contracts.git
   ```

4. **Build and Test**

   ```bash
   forge install
   forge build
   forge test
   ```

## Development Workflow

### 1. Create a Feature Branch

```bash
git checkout -b feature/your-feature-name
# or
git checkout -b fix/your-bug-fix
```

### 2. Make Your Changes

- Write clean, readable Solidity.
- Follow the existing file layout (`src/core`, `src/libraries`, `src/storage`).
- Add comments for non-obvious logic, especially around price curves and matching.

### 3. Test Your Changes

Before opening a PR, run locally:

```bash
forge fmt --check
forge build
forge test -vv
forge coverage
```

If you change gas-sensitive paths, update the snapshot:

```bash
forge snapshot
```

### 4. Commit Your Changes

```bash
git add .
git commit -m "feat: add x"   # or fix:/docs:/refactor:/test:/chore:
```

### 5. Keep Your Branch Updated

```bash
git fetch upstream
git rebase upstream/main
```

### 6. Push Your Changes

```bash
git push origin feature/your-feature-name
```

## Pull Request Guidelines

### Before Submitting

- [ ] Your code follows the project's style guidelines
- [ ] You've tested your changes thoroughly (`forge build`, `forge test -vv`, `forge fmt --check`)
- [ ] You've updated relevant documentation (including `Deployments.md` if you changed deployment behavior)
- [ ] Your commits are clean and well-organized
- [ ] You've rebased with the latest upstream changes

### After Submission

- Post your PR in `#windmill-exchange` on Discord for visibility (**IMPORTANT**).
- Respond to review comments promptly (CodeRabbit runs on every PR).
- Make requested changes in new commits.
- Use `[WIP]` in your PR title for incomplete PRs.

## Code Style Guidelines

- Solidity `^0.8.23`, EVM `paris`.
- Follow `forge fmt` formatting (see `[fmt]` in `foundry.toml`).
- Use NatSpec (`@dev`, `@param`, `@return`) for every public/external function.
- Prefer custom errors over `require` strings.
- Keep storage layout organized in `src/storage`; avoid magic constants.
- Add tests for every new function and every edge case in price/math logic.

## Security

Smart contracts handle value. Please:

- Never deploy secrets or private keys; use `.env` variables.
- Report vulnerabilities privately via Discord or Telegram — do not open a public issue.
- When in doubt about reentrancy, gas, or order of operations, flag it in the PR description.

## Community Guidelines

- Be respectful and inclusive; provide constructive feedback.
- If your work is taking longer than expected, comment on Discord with updates.
- Check existing PRs before starting to avoid duplication.
- One contributor per issue (unless specified otherwise).

Thank you for contributing to Windmill EVM Contracts. Your work makes the protocol safer and faster.