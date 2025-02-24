# TokenFlex: Dynamic Subscription Tokenization Platform

TokenFlex is a blockchain-based subscription platform that leverages NFTs to manage access rights and membership tiers. Built on Clarity for the Stacks ecosystem, TokenFlex enables content creators and service providers to tokenize their subscription offerings and grant access based on membership levels.

## 🌟 Key Features

- **Tokenized Memberships**: Each subscription is represented as a unique NFT, establishing verifiable ownership and enabling transferability
- **Tiered Access**: Multiple membership plans with different durations and price points
- **Fine-grained Resource Control**: Configure access to specific resources based on membership levels
- **On-chain Verification**: Full subscription lifecycle management on the blockchain

## 🛠️ Technical Implementation

The TokenFlex platform consists of a Clarity smart contract that implements:

- NFT trait compliance for token management
- Membership plan configuration and management
- User subscription tracking with expiration dates
- Resource management with tier-based access control
- Administrative functions for platform governance

## 📋 Membership Plans

TokenFlex comes pre-configured with three membership tiers:

| Plan | Duration | Price |
|------|----------|-------|
| Basic | 1 day | 100 STX |
| Premium | 30 days | 250 STX |
| Elite | 365 days | 1000 STX |

Plans can be customized or expanded by the contract administrator.

## 🔍 Smart Contract Functions

### User Functions

- `join-plan`: Subscribe to a specific membership plan
- `terminate-membership`: Cancel an active membership
- `move-asset`: Transfer a membership NFT to another user

### Read-Only Functions

- `get-membership-plan`: Get details of a specific membership plan
- `get-member-details`: Get membership details for a user
- `is-membership-valid`: Check if a user's membership is active
- `can-access-resource`: Verify if a user can access a specific resource

### Administrative Functions

- `create-membership-plan`: Create a new membership tier
- `register-resource`: Add a new resource to the platform
- `configure-resource-access`: Set access permissions for resources
- `set-platform-status`: Enable or disable the platform

## 🚀 Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) for local development and testing
- [Stacks Wallet](https://www.hiro.so/wallet) for interacting with the deployed contract

### Deployment

1. Clone this repository
2. Install dependencies: `npm install`
3. Test locally: `clarinet test`
4. Deploy to testnet: `clarinet deploy --testnet`

### Usage Examples

```clarity
;; Subscribe to the Basic plan
(contract-call? .tokenflex join-plan u1)

;; Check if subscription is active
(contract-call? .tokenflex is-membership-valid tx-sender)

;; Access a resource
(contract-call? .tokenflex can-access-resource tx-sender u1)
```

## 🔐 Security Considerations

- Only the contract administrator can create plans and register resources
- Memberships automatically expire based on their duration
- Ownership validation ensures only valid token holders can access resources

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

