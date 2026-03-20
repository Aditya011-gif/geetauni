# Agrichain: Tech Stack & System Workflow

This document provides a concise overview of the technologies used in the Agrichain platform, accompanied by a global architectural flowchart ideal for presentation slides.

---

## 1. Technology Stack

### App & Frontend
- **Flutter / Dart**: Cross-platform mobile (Android, iOS), web, and desktop application framework.

### Backend & Cloud Services (Web2)
- **Firebase Authentication**: User identity and secure session management.
- **Firebase Firestore**: Scalable NoSQL real-time database for off-chain metadata.
- **Firebase Cloud Storage**: Secure object storage for media and verification documents (PDFs, crop images).
- **Firebase Cloud Messaging (FCM)**: Real-time push notifications.

### Blockchain & Smart Contracts (Web3)
- **EVM-Compatible Blockchain**: Network (Ethereum / Polygon) for executing decentralized logic.
- **Solidity**: Smart contract language used for `Ballot`, `Storage`, and `Owner` contracts.
- **Remix IDE**: Fast compilation and testing environment.
- **RPC Providers**: Infura / Alchemy acting as the gateway between the app and the EVM.
- **Ethers.js / Web3.js**: JavaScript libraries for broadcasting transactions.

### Third-Party APIs
- **Razorpay**: Fiat payment gateway for processing traditional financial transactions.
- **DigiLocker**: Integrated for official KYC (Know Your Customer) and credential verification.

---

## 2. Global System Workflow Diagram

*This diagram illustrates the multi-layered interactions between the Client App, Web2 Cloud Services, Web3 Blockchain Services, and External APIs.*

```mermaid
flowchart TD
    %% Client Layer
    subgraph ClientLayer [Client Layer]
        App[Agrichain Mobile & Web App <br> Flutter / Dart]
    end

    %% Web2 Layer
    subgraph Web2Layer [Cloud Infrastructure - Web2]
        Auth[Firebase Auth <br> Login / Sessions]
        DB[(Firestore Database <br> Off-Chain Data)]
        Storage[(Cloud Storage <br> PDFs / Images)]
        Notifications[Firebase Cloud Messaging <br> Push Alerts]
    end

    %% External Integrations Layer
    subgraph ExternalLayer [External Providers]
        Fiat[Razorpay <br> Payment Gateway]
        KYC[DigiLocker Sandbox <br> Identity Verification]
    end

    %% Web3 Layer
    subgraph Web3Layer [Decentralized Web3 Layer]
        RPC[Infura / Alchemy <br> RPC Nodes]
        EVM[EVM-Compatible Blockchain]
        Contracts[(Solidity Smart Contracts <br> Asset Storage, Voting)]
    end

    %% Styling blocks
    style ClientLayer fill:#f9f,stroke:#333,stroke-width:2px
    style Web2Layer fill:#bbf,stroke:#333,stroke-width:2px
    style ExternalLayer fill:#dfd,stroke:#333,stroke-width:2px
    style Web3Layer fill:#ffb,stroke:#333,stroke-width:2px

    %% Connections
    App <-->|1. Manage Secure Sessions| Auth
    App <-->|2. Fast UI Sync & Profiles| DB
    App <-->|3. Manage Media & Docs| Storage
    Notifications -.->|4. Real-time User Alerts| App

    App <-->|5. Process Fiat Payments| Fiat
    App <-->|6. Fetch KYC Credentials| KYC

    App <-->|7. Sign & Broadcast Tx| RPC
    RPC <-->|8. Relay Interactions| EVM
    EVM <-->|9. Execute Decentralized Logic| Contracts
```
