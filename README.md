# 💸 Foundry Fund Me

[![Foundry](https://img.shields.io/badge/Built%20with-Foundry-black?logo=ethereum)](https://book.getfoundry.sh/)
[![Solidity](https://img.shields.io/badge/Solidity-%5E0.8.18-informational)](https://soliditylang.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)
[![CI](https://github.com/AdeolaEsuruoso/foundry-fund-me/actions/workflows/test.yml/badge.svg)](https://github.com/AdeolaEsuruoso/foundry-fund-me/actions)

A decentralized crowdfunding smart contract that lets users fund a contract with ETH, provided it meets a minimum USD value threshold enforced on-chain via a **Chainlink price feed**. Built and tested with **Foundry**, with full deployment and interaction scripting, and cross-chain compatibility for **zkSync**.

---

## 📖 Table of Contents

- [Overview](#overview)
- [How It Works](#how-it-works)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
- [Testing](#testing)
- [Deployment](#deployment)
- [Key Design Decisions](#key-design-decisions)
- [License](#license)
- [Acknowledgements](#acknowledgements)

---

## Overview

`FundMe` is a simple but production-patterned smart contract system demonstrating core Solidity engineering practices:

- On-chain price conversion using Chainlink's `AggregatorV3Interface`
- Owner-restricted withdrawal logic with custom errors for gas efficiency
- Network-aware configuration (mainnet, testnet, and local Anvil price feeds handled automatically)
- Full unit and integration test coverage, including fork tests against live price feeds
- Deployment and interaction scripts for real-world usage, not just local testing
- zkSync compatibility checks and conditional test execution

---

## How It Works

1. A user calls `fund()` and attaches ETH.
2. The contract asks the Chainlink price feed for the current ETH/USD price.
3. It converts `msg.value` into its USD equivalent and reverts (via a custom error) if it's under the minimum funding threshold.
4. Funders are tracked in an array + mapping so contributions are auditable.
5. The contract owner can call `withdraw()` to pull all funds out and reset balances.

The price feed address is never hardcoded into the contract logic — `HelperConfig.s.sol` resolves the correct feed per network (mainnet, Sepolia, or a freshly deployed Anvil mock), keeping the contract portable across environments including zkSync Era.

---

## Tech Stack

| Layer | Tool |
|---|---|
| Smart contracts | Solidity `^0.8.18` |
| Framework | [Foundry](https://book.getfoundry.sh/) (Forge, Cast, Anvil) |
| Oracle | [Chainlink Price Feeds](https://docs.chain.link/data-feeds) |
| Testing | Forge unit tests, integration tests, forked mainnet/testnet tests |
| Deployment tooling | Foundry scripting (`forge script`), `foundry-devops` for deployment lookups |
| CI/CD | GitHub Actions |
| L2 support | zkSync Era |

---

## Project Structure

```
├── script/
│   ├── DeployFundMe.s.sol      # Deployment script
│   ├── HelperConfig.s.sol      # Network-specific config (mainnet/sepolia/anvil)
│   └── Interactions.s.sol      # Fund & withdraw interaction scripts
├── src/
│   ├── FundMe.sol               # Core contract
│   └── PriceConverter.sol       # Chainlink price conversion library
├── test/
│   ├── unit/                    # Unit tests
│   ├── integration/             # Integration tests
│   └── mocks/                   # Mock price feed for local testing
└── Makefile                     # Common commands (build, test, deploy, fund, withdraw)
```

---

## Getting Started

### Requirements

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- [Git](https://git-scm.com/)

### Installation

```bash
git clone https://github.com/AdeolaEsuruoso/foundry-fund-me
cd foundry-fund-me
make install
```

### Build

```bash
make build
```

---

## Testing

```bash
forge test
```

Run with verbosity for full call traces:

```bash
forge test -vvvv
```

Check test coverage:

```bash
forge coverage
```

Tests are split across `unit/`, `integration/`, and mock-backed local runs, plus forked tests that run against live Sepolia/mainnet price feeds to validate real oracle behavior.

---

## Deployment

Create a `.env` file (see `.env.example`) with:

```
SEPOLIA_RPC_URL=<your_rpc_url>
ETHERSCAN_API_KEY=<your_etherscan_api_key>
ACCOUNT=<your_foundry_keystore_account_name>
ACCOUNT_ADDRESS=<your_wallet_address>
```

> Private keys are never stored in plaintext. This project uses Foundry's encrypted keystore (`cast wallet import`) rather than raw `--private-key` flags.

Deploy to Sepolia (with automatic Etherscan verification):

```bash
make deploy-sepolia
```

Fund and withdraw from the deployed contract:

```bash
make fund
make withdraw
```

---

## Key Design Decisions

- **Custom errors over `require` strings** — reduces deployment and runtime gas cost.
- **Immutable owner, constant minimum funding threshold** — cheaper storage reads for values that never change post-deployment.
- **Network-agnostic price feed resolution** — `HelperConfig.s.sol` automatically supplies the correct Chainlink feed address per chain, and deploys a mock feed on local Anvil so tests never depend on a live network.
- **Encrypted local keystore over raw private keys** — deployment scripts and Makefile targets use `--account` rather than exposing keys in shell history or CI logs.

---

## License

This project is licensed under the MIT License — see the [LICENSE](./LICENSE) file for details.

---

## Acknowledgements

Built while working through [Cyfrin Updraft](https://updraft.cyfrin.io/)'s Foundry Fundamentals course, extended with additional tooling and deployment automation.

---

<p align="center">
  Built with 🔧 Foundry, secured by ⛓ Chainlink.
</p>
