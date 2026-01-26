# YieldBase 🚀

A decentralized yield aggregator built on Base that automatically optimizes your crypto returns by deploying funds across multiple DeFi protocols.

## Overview

YieldBase helps users maximize their yields by:
- Automatically finding the best interest rates across protocols
- Compounding earnings automatically
- Minimizing gas costs through batched operations
- Providing a simple deposit/withdraw interface

## Features

✅ **Multi-Strategy Support** - Deploy to Aave, Moonwell, and more  
✅ **Auto-Compounding** - Maximize returns through automatic reinvestment  
✅ **Share-Based Accounting** - Fair distribution regardless of entry time  
✅ **Gas Optimized** - Built for Base's low-fee environment  
✅ **Transparent Fees** - 10% performance fee on profits only  
✅ **Secure** - ReentrancyGuard and audited OpenZeppelin contracts

## Smart Contracts

### Core Contracts

- **BaseVault.sol** - Main vault where users deposit and withdraw
- **AaveStrategy.sol** - Strategy for Aave V3 lending
- **CompoundStrategy.sol** - Strategy for Moonwell/Compound lending

### Contract Addresses (Base Mainnet)

```
BaseVault: [Deployed after deployment]
AaveStrategy: [Deployed after deployment]
```

## Architecture

```
User
  ↓ deposits USDC
BaseVault (issues shares)
  ↓ deploys funds
AaveStrategy / CompoundStrategy
  ↓ earns yield
Aave / Moonwell
  ↓ harvest profits
BaseVault (compounds & takes 10% fee)
  ↓ withdraw
User (gets USDC + yield)
```

## Installation

### Prerequisites

- Node.js v18+
- npm or yarn
- Hardhat

### Setup

```bash
# Clone the repository
git clone https://github.com/yourusername/yieldbase
cd yieldbase

# Install dependencies
npm install

# Copy environment file
cp .env.example .env

# Add your private key and RPC URLs to .env
```

### Environment Variables

Create a `.env` file:

```env
PRIVATE_KEY=your_private_key_here
BASE_RPC_URL=https://mainnet.base.org
BASE_SEPOLIA_RPC_URL=https://sepolia.base.org
BASESCAN_API_KEY=your_basescan_api_key
```

## Deployment

### Deploy to Base Testnet (Sepolia)

```bash
# Deploy contracts
npx hardhat ignition deploy ./ignition/modules/YieldBase.js --network base-sepolia

# Activate strategy
npx hardhat run scripts/activate-strategy.js --network base-sepolia

# Verify contracts
npx hardhat ignition verify chain-84532
```

### Deploy to Base Mainnet

```bash
# Deploy contracts
npx hardhat ignition deploy ./ignition/modules/YieldBase.js --network base

# Activate strategy
npx hardhat run scripts/activate-strategy.js --network base

# Verify contracts
npx hardhat ignition verify chain-8453
```

## Usage

### For Users

#### Deposit

```javascript
// Approve USDC
await usdc.approve(vaultAddress, amount);

// Deposit and receive shares
await vault.deposit(amount);
```

#### Withdraw

```javascript
// Withdraw all your shares
const shares = await vault.balanceOf(userAddress);
await vault.withdraw(shares);
```

#### Check Balance

```javascript
// Get your share balance
const shares = await vault.balanceOf(userAddress);

// Preview how much USDC you can withdraw
const assets = await vault.previewWithdraw(shares);
```

### For Developers

#### Compile Contracts

```bash
npx hardhat compile
```

#### Run Tests

```bash
npx hardhat test
```

#### Run Local Node

```bash
npx hardhat node
```

#### Deploy Locally

```bash
npx hardhat ignition deploy ./ignition/modules/YieldBase.js --network localhost
```

## Project Structure

```
yieldbase/
├── contracts/
│   ├── BaseVault.sol           # Main vault contract
│   ├── AaveStrategy.sol        # Aave lending strategy
│   └── CompoundStrategy.sol    # Compound/Moonwell strategy
├── ignition/
│   └── modules/
│       └── YieldBase.js        # Deployment configuration
├── scripts/
│   ├── activate-strategy.js    # Post-deployment setup
│   └── harvest.js              # Manual harvest script
├── test/
│   └── YieldBase.test.js       # Contract tests
├── hardhat.config.js           # Hardhat configuration
└── README.md
```

## How It Works

### 1. Deposit Flow

1. User approves USDC to vault contract
2. User calls `deposit(amount)`
3. Vault mints shares based on current share price
4. Vault deploys USDC to active strategy
5. Strategy deposits into Aave/Moonwell

### 2. Yield Generation

- Aave/Moonwell pays interest on deposited USDC
- Interest accumulates in aTokens/cTokens
- `harvest()` can be called to compound profits

### 3. Withdrawal Flow

1. User calls `withdraw(shares)`
2. Vault calculates USDC amount based on shares
3. Vault withdraws from strategy if needed
4. Vault burns user's shares
5. Vault transfers USDC to user

### 4. Share Price Mechanics

```
Share Price = Total Assets / Total Shares

Example:
- Initially: 1000 USDC deposited = 1000 shares (1:1)
- After yield: 1100 USDC total, 1000 shares (1.1:1)
- New depositor: 100 USDC = 90.9 shares
```

## Fee Structure

- **Performance Fee**: 10% on profits only
- **Management Fee**: None
- **Deposit Fee**: None
- **Withdrawal Fee**: None (only gas)

## Supported Protocols

### Base Mainnet

| Protocol | Asset | Strategy Contract |
|----------|-------|-------------------|
| Aave V3  | USDC  | AaveStrategy      |
| Moonwell | USDC  | CompoundStrategy  |

### Adding New Strategies

To add a new protocol:

1. Create strategy contract implementing `IStrategy`
2. Deploy strategy with vault address
3. Call `vault.setStrategy(newStrategyAddress)`

## Security

### Audits

- [ ] Pending external audit
- [x] Uses audited OpenZeppelin contracts
- [x] ReentrancyGuard on all state-changing functions

### Known Limitations

- Strategy changes require owner intervention
- Single strategy active at a time
- No emergency pause function (consider adding)

### Bug Bounty

Report security vulnerabilities to: security@yieldbase.xyz

## Testing

```bash
# Run all tests
npx hardhat test

# Run with coverage
npx hardhat coverage

# Run specific test file
npx hardhat test test/YieldBase.test.js

# Run with gas reporting
REPORT_GAS=true npx hardhat test
```

## Scripts

### Harvest Yields

```bash
npx hardhat run scripts/harvest.js --network base
```

### Change Strategy

```bash
npx hardhat run scripts/change-strategy.js --network base
```

### Check APY

```bash
npx hardhat run scripts/check-apy.js --network base
```

## Mainnet Deployment Checklist

- [ ] Audit smart contracts
- [ ] Test on Base Sepolia
- [ ] Verify all protocol addresses
- [ ] Set up monitoring (APY tracking, TVL)
- [ ] Deploy with multisig owner
- [ ] Enable timelock for strategy changes
- [ ] Set up auto-harvest cron job
- [ ] Write comprehensive tests
- [ ] Document emergency procedures

## Roadmap

### Phase 1 (Current)
- [x] Core vault functionality
- [x] Aave strategy
- [x] Basic deployment scripts
- [ ] Frontend interface

### Phase 2
- [ ] Multiple active strategies
- [ ] Auto-rebalancing between protocols
- [ ] Additional tokens (ETH, DAI)
- [ ] Governance token

### Phase 3
- [ ] Advanced strategies (LP farming)
- [ ] Cross-chain deployment
- [ ] DAO governance
- [ ] Mobile app

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Resources

- [Base Documentation](https://docs.base.org)
- [Aave V3 Docs](https://docs.aave.com/developers/)
- [Moonwell Docs](https://docs.moonwell.fi/)
- [Hardhat Ignition](https://hardhat.org/ignition/docs/getting-started)
- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts/)

## Disclaimer

This software is provided "as is" without warranty. Use at your own risk. DeFi protocols carry inherent risks including smart contract bugs, economic exploits, and market volatility. Never invest more than you can afford to lose.

---

**Built with ❤️ on Base**