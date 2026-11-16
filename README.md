# B2B Supply Chain Escrow & Product Acceptance DApp

**Student Name:** Oleh Mekeda  
**Student Number:** L00206118
**Module:** Blockchain Technology (TECHIT904)  
**Assessment:** Decentralised Application and Report  

## Overview
This repository contains a Solidity-based Smart Contract and Decentralised Application (DApp) for B2B supply chain management. The application facilitates trustless escrow transactions, tracking order states from funding and dispatch to physical delivery, quality inspection, and automated fund settlement or refunds.

## Core Lifecycle States
1. **Created:** Order terms initialized between Buyer and Seller.
2. **FundsDeposited:** Buyer locks payment in escrow contract.
3. **Dispatched:** Seller marks goods as shipped.
4. **Delivered:** Physical arrival confirmed at buyer's facility; inspection window starts.
5. **AcceptedAndPaid:** Inspection passed; escrow automatically releases funds to the seller.
6. **RejectedAndRefunded:** Inspection failed or non-compliance detected; escrow refunds buyer.

## Project Structure
- `contracts/`: Solidity smart contract source files (`SupplyChainEscrow.sol`).
