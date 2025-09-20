# CommunityBudget

A participatory democracy platform for local spending priorities and project funding built on the Stacks blockchain using Clarity smart contracts.

## Overview

CommunityBudget enables communities to democratically propose, vote on, and fund local projects through a transparent, blockchain-based governance system. Community members can submit funding proposals, participate in voting processes, and track budget allocation in real-time.

## Features

- **Democratic Proposal System**: Community members can submit project proposals with detailed descriptions and funding amounts
- **Transparent Voting**: Secure voting mechanism with vote tracking and duplicate prevention
- **Budget Management**: Real-time tracking of total, allocated, and available community funds
- **Member Management**: Owner-controlled community membership system
- **Proposal Lifecycle**: Complete workflow from submission through voting to funding
- **Status Tracking**: Real-time proposal status updates (active, approved, rejected, funded)
- **Voting Period Control**: Configurable voting periods for each proposal
- **Fund Allocation**: Automatic budget allocation tracking for approved proposals

## Technical Specifications

- **Blockchain**: Stacks
- **Smart Contract Language**: Clarity v2
- **Epoch**: 2.5
- **Contract Version**: 1.0.0

### Contract Architecture

The smart contract maintains several key data structures:
- **Proposals**: Core proposal data including title, description, amount, votes, and status
- **Votes**: Individual vote tracking to prevent double voting
- **Community Members**: Eligible voter registry
- **Budget Variables**: Total, allocated, and available budget tracking

## Installation

### Prerequisites

- [Clarinet](https://docs.hiro.so/clarinet) installed
- Node.js and npm for testing
- Stacks wallet for deployment

### Setup

1. Clone the repository:
```bash
git clone <repository-url>
cd CommunityBudget
```

2. Navigate to the contract directory:
```bash
cd CommunityBudget_contract
```

3. Install dependencies:
```bash
npm install
```

4. Check contract syntax:
```bash
clarinet check
```

## Usage Examples

### Initialize Community Budget

```clarity
(contract-call? .CommunityBudget initialize-budget u1000000)
```

### Add Community Member

```clarity
(contract-call? .CommunityBudget add-community-member 'SP1234567890ABCDEF)
```

### Submit a Proposal

```clarity
(contract-call? .CommunityBudget submit-proposal
    "Park Renovation"
    "Renovate the community park with new playground equipment"
    u50000
    u144) ;; 144 blocks voting period
```

### Vote on a Proposal

```clarity
(contract-call? .CommunityBudget vote-on-proposal u1 true) ;; Vote for proposal #1
```

### Finalize and Fund Proposal

```clarity
;; After voting period ends
(contract-call? .CommunityBudget finalize-proposal u1)

;; If approved, fund the proposal
(contract-call? .CommunityBudget fund-proposal u1)
```

## Contract Functions

### Public Functions

#### Administrative Functions
- `initialize-budget(budget: uint)` - Set initial community budget (owner only)
- `add-community-member(member: principal)` - Add voting member (owner only)
- `remove-community-member(member: principal)` - Remove voting member (owner only)
- `add-budget(additional-funds: uint)` - Add funds to community budget (owner only)
- `fund-proposal(proposal-id: uint)` - Fund approved proposal (owner only)

#### Community Functions
- `submit-proposal(title, description, amount, voting-period)` - Submit new proposal
- `vote-on-proposal(proposal-id: uint, vote-for: bool)` - Vote on active proposal
- `finalize-proposal(proposal-id: uint)` - Finalize voting after period ends

### Read-Only Functions

#### Proposal Information
- `get-proposal(proposal-id: uint)` - Get complete proposal details
- `get-current-proposal-id()` - Get latest proposal ID
- `get-proposal-status(proposal-id: uint)` - Get proposal status
- `is-voting-ended(proposal-id: uint)` - Check if voting period ended

#### Budget Information
- `get-total-budget()` - Get total community budget
- `get-allocated-budget()` - Get currently allocated funds
- `get-available-budget()` - Get remaining available funds

#### Voting Information
- `has-voted(proposal-id: uint, voter: principal)` - Check if user voted
- `get-vote(proposal-id: uint, voter: principal)` - Get user's vote
- `is-community-member(member: principal)` - Check membership status

## Deployment Guide

### Local Development

1. Start Clarinet console:
```bash
clarinet console
```

2. Deploy and test functions:
```clarity
::deploy_contracts
::get_contracts
```

### Testnet Deployment

1. Configure testnet settings in `settings/Testnet.toml`
2. Deploy to testnet:
```bash
clarinet deployments generate --testnet
clarinet deployments apply --testnet
```

### Mainnet Deployment

1. Configure mainnet settings in `settings/Mainnet.toml`
2. Deploy to mainnet:
```bash
clarinet deployments generate --mainnet
clarinet deployments apply --mainnet
```

## Testing

Run the test suite:

```bash
npm test
```

Run tests with coverage:

```bash
npm run test:report
```

Watch mode for development:

```bash
npm run test:watch
```

## Security Considerations

### Access Controls
- Contract owner has administrative privileges for budget and membership management
- Only community members can submit proposals and vote
- Voting is restricted to active community members

### Voting Security
- Double voting prevention through vote tracking
- Voting period enforcement prevents late votes
- Simple majority voting system for proposal approval

### Budget Protection
- Proposals cannot exceed available budget
- Budget allocation tracking prevents overspending
- Owner-only funding execution provides additional control

### Error Handling
The contract includes comprehensive error codes:
- `u100`: Owner-only function access denied
- `u101`: Proposal not found
- `u102`: User already voted
- `u103`: Proposal voting period ended
- `u104`: Proposal voting period not ended
- `u105`: Insufficient funds
- `u106`: Invalid amount
- `u107`: Proposal not approved
- `u108`: Proposal already funded

## Project Structure

```
CommunityBudget/
├── README.md
└── CommunityBudget_contract/
    ├── contracts/
    │   └── CommunityBudget.clar
    ├── tests/
    │   └── CommunityBudget.test.ts
    ├── settings/
    │   ├── Devnet.toml
    │   ├── Testnet.toml
    │   └── Mainnet.toml
    ├── Clarinet.toml
    ├── package.json
    ├── tsconfig.json
    └── vitest.config.js
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## License

This project is open source. Please refer to the license file for details.

## Support

For questions, issues, or contributions, please refer to the project's issue tracker or contact the development team.