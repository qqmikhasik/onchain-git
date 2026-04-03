# Onchain Git

Version control system for upgradeable smart contracts using the **Beacon Proxy** pattern.

Implements on-chain version history tracking with rollback capability, analogous to Git's version control — but for smart contract implementations.

## Architecture

```
┌─────────────────────────────┐
│      VersionedBeacon         │ ← extends UpgradeableBeacon
│  versionHistory[]            │
│  currentVersionIndex         │
│  upgradeToWithDescription()  │
│  rollbackTo()                │
└──────────┬──────────────────┘
           │ implementation()
     ┌─────┼─────┐
     ▼     ▼     ▼
  TokenV1 TokenV2 TokenV3     ← upgradeable ERC-20 implementations
     ▲
     │ delegatecall
  BeaconProxy                 ← user-facing contract (stores data)
```

### Contracts

| Contract | Description |
|----------|-------------|
| `VersionedBeacon` | Beacon with version history array, rollback, and upgrade tracking |
| `TokenV1` | Basic ERC-20 token (mint, burn) |
| `TokenV2` | Adds transfer fee in basis points (ERC-7201 namespaced storage) |
| `TokenV3` | Adds pause/unpause functionality |

### Key Features

- **`versionHistory[]`** — append-only array of all implementation versions
- **`currentVersionIndex`** — index of the active implementation
- **`upgradeToWithDescription()`** — upgrade with version metadata (address, timestamp, description)
- **`rollbackTo()`** — revert to any previous version (owner-only)
- **ERC-7201 namespaced storage** — no storage collisions across versions

## Setup

```bash
# Install dependencies
forge install

# Build
forge build

# Run tests
forge test -vvvv
```

## Testing

14 test cases covering:
- Deployment and initialization
- Mint/burn operations
- Version history tracking
- Upgrade to V2 (transfer fee) and V3 (pausable)
- Storage persistence across upgrades
- Rollback functionality and history preservation
- Access control (owner-only upgrade/rollback)
- Edge cases (invalid index)

## Deployment

```bash
# Start local node
anvil

# Deploy (uses first Anvil account)
export PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
forge script script/Deploy.s.sol --rpc-url http://127.0.0.1:8545 --broadcast

# Upgrade to V2
export BEACON_ADDRESS=<from deploy output>
export PROXY_ADDRESS=<from deploy output>
export TREASURY_ADDRESS=0x70997970C51812dc3A010C7d01b50e0d17dc79C8
forge script script/Upgrade.s.sol --rpc-url http://127.0.0.1:8545 --broadcast

# Rollback to V1
export TARGET_VERSION=0
forge script script/Rollback.s.sol --rpc-url http://127.0.0.1:8545 --broadcast
```

## Tech Stack

- Solidity 0.8.28
- OpenZeppelin Contracts V5.1.0
- Foundry (forge, anvil, cast)
