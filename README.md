# B2B Supply Chain Escrow & Product Acceptance DApp

**Student Name:** Oleh Mekeda  
**Student Number:** L00206118  
**Module:** Blockchain Technology (TECHIT904)  
**Assessment:** Decentralised Application and Report  
**Repository:** `b2b-supplychain-escrow`

## Overview
This repository contains a Solidity-based Smart Contract and Decentralised Application (DApp) architecture for B2B supply chain management. The application facilitates trustless escrow transactions, tracking order states from seller-initiated proforma offer creation and buyer funding to dispatch, physical delivery, third-party quality inspection, and automated fund settlement or buyer refund via a Pull-Payment mechanism.

## Core Lifecycle States
1. **Created:** Proforma offer terms and specification hashes initialized by Seller.
2. **FundsDeposited:** Buyer deposits exact order payment into the escrow contract.
3. **Dispatched:** Seller confirms shipment and dispatch of physical goods.
4. **Delivered:** Seller confirms physical delivery to the buyer's facility.
5. **AcceptedAndPaid:** Nominated inspector submits a positive quality report; Seller claims escrow payment via Pull-Payment.
6. **RejectedAndRefunded:** Inspector submits a negative report or deadline expires; Buyer claims full escrow refund via Pull-Payment.

## Project Structure
- `contracts/`: Smart contract source files (`SupplyChainEscrow.sol`).
- `test/`: Hardhat automated unit test suite (`SupplyChainEscrow.test.js`).
- `docs/`: Architectural documentation and workflow diagrams (`escrow_architecture.md`).
- `hardhat.config.js`: Hardhat environment configuration (Solidity compiler `0.8.20`).
- `package.json`: Project dependencies and script declarations.

## Testing and Execution
To compile the smart contract and execute the automated unit test suite using Hardhat:

1. Install project dependencies:
   `npm install`
2. Execute automated test suite (7/7 passing):
   `npx hardhat test`

## Code Provenance, Libraries, and AI Collaboration

### 1. External Libraries & Infrastructure
- **Hardhat (v2.22.0) & `@nomicfoundation/hardhat-toolbox`:** Used for local EVM deployment, compilation, and automated unit test orchestration.
- **Ethers.js (v6) & Chai:** Utilised for contract abstraction, balance verification, and test assertion evaluation.
- **Solidity (`^0.8.20`):** Smart contract programming language with custom error handling.

### 2. Generative AI Assistance & Code Drafting
- **AI Pair Programming Disclosure:** Generative AI tools (Gemini / ChatGPT) were consulted as interactive coding assistants during development to assist with initial Solidity syntax snippets, Hardhat test boilerplate construction, and resolving local Node.js/EVM dependency conflicts.

### 3. Author's Original Contribution & Architecture
- **Domain & State Architecture:** Independently designed the custom 6-state deterministic finite state machine (`Created`, `FundsDeposited`, `Dispatched`, `Delivered`, `AcceptedAndPaid`, `RejectedAndRefunded`) tailored to B2B procurement risk profiles.
- **Cryptographic & Financial Logic:** Engineered the seller-initiated proforma workflow, specification commitment hashing, and security refactoring to enforce the Pull-Payment settlement pattern (`call{value: ...}`) adhering to Checks-Effects-Interactions (CEI).
- **Access Control & Safety:** Designed Role-Based Access Control (RBAC) constraints (`seller`, `buyer`, `inspector`) and custom error reverts to prevent unauthorized execution and state tampering.
- **Verification:** Designed, implemented, and validated the complete 7-scenario Hardhat automated test suite (`SupplyChainEscrow.test.js`).