# Tokenized Decentralized Addiction Recovery Networks

A comprehensive blockchain-based platform for addiction recovery support, built on the Stacks blockchain using Clarity smart contracts.

## Overview

This project implements a decentralized addiction recovery ecosystem that connects individuals with appropriate treatment programs, facilitates peer support communities, tracks recovery progress, and provides family support resources.

## System Architecture

### Core Contracts

1. **Treatment Matching Contract** (`treatment-matching.clar`)
    - Connects individuals with appropriate recovery programs
    - Manages treatment provider registry
    - Handles matching algorithms based on user needs

2. **Support Group Coordination Contract** (`support-group.clar`)
    - Facilitates peer recovery communities and meetings
    - Manages group creation and membership
    - Coordinates meeting schedules and attendance

3. **Progress Monitoring Contract** (`progress-monitoring.clar`)
    - Tracks sobriety milestones and recovery achievements
    - Issues achievement tokens and badges
    - Maintains privacy-focused progress records

4. **Family Support Contract** (`family-support.clar`)
    - Provides resources and guidance for affected family members
    - Manages family member registration and access
    - Coordinates family support group activities

5. **Relapse Prevention Contract** (`relapse-prevention.clar`)
    - Offers ongoing support and crisis intervention services
    - Manages emergency contact systems
    - Provides 24/7 support network coordination

## Token Economics

- **Recovery Tokens (RCT)**: Earned through participation and milestones
- **Support Tokens (SPT)**: Used for accessing premium support services
- **Achievement NFTs**: Commemorative tokens for significant milestones

## Privacy & Security

- All personal health information is encrypted
- Zero-knowledge proofs for progress verification
- Decentralized identity management
- HIPAA-compliant data handling

## Getting Started

### Prerequisites

- Clarinet CLI installed
- Stacks wallet configured
- Node.js for testing environment

### Installation

\`\`\`bash
git clone <repository-url>
cd addiction-recovery-network
clarinet check
\`\`\`

### Testing

\`\`\`bash
npm test
\`\`\`

### Deployment

\`\`\`bash
clarinet deploy --testnet
\`\`\`

## Contract Interactions

### For Recovery Seekers

1. Register with treatment matching system
2. Get matched with appropriate programs
3. Join support groups
4. Track progress and earn achievements
5. Access crisis intervention when needed

### For Family Members

1. Register for family support access
2. Access educational resources
3. Join family support groups
4. Receive updates on loved one's progress (with consent)

### For Treatment Providers

1. Register treatment programs
2. Update availability and specializations
3. Receive matched referrals
4. Report treatment outcomes

## Contributing

Please read our contributing guidelines and code of conduct before submitting pull requests.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For technical support, please open an issue in the GitHub repository.
For crisis intervention, please contact your local emergency services.
