// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title B2B Supply Chain Escrow & Product Acceptance
 * @dev Smart contract managing escrow funds, shipping tracking, physical delivery, inspection, and automated settlement.
 */
contract SupplyChainEscrow {

    // Lifecycle states of a B2B supply chain escrow order
    enum State { 
        Created, 
        FundsDeposited, 
        Dispatched, 
        Delivered, 
        AcceptedAndPaid, 
        RejectedAndRefunded 
    }