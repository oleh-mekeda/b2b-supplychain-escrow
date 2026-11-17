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

// 2. Structure defining all properties of an escrow order
    struct EscrowOrder {
        address payable buyer;        // Address of the buyer
        address payable seller;       // Address of the seller
        address inspector;            // Address of the independent quality inspector (e.g., SGS)
        uint256 amount;               // Escrow amount in Wei
        bytes32 itemHash;             // Cryptographic hash of product specification / invoice
        uint256 deliveryDeadline;     // Timestamp deadline for the seller to dispatch goods
        uint256 deliveryTimestamp;    // Timestamp when goods physically arrived at the buyer's facility
        uint256 inspectionWindow;     // Allowed time window (in seconds) for quality inspection
        State state;                  // Current state of the escrow order
        bool isInspected;             // Flag indicating whether inspection was completed
    }

    // 3. State variables (Blockchain Storage)
    uint256 public orderCount;
    mapping(uint256 => EscrowOrder) public orders;

    // 4. Events for DApp interface integration and logging
    event OrderCreated(
        uint256 indexed orderId, 
        address indexed buyer, 
        address indexed seller, 
        address inspector,
        uint256 amount
    );
    event FundsDeposited(uint256 indexed orderId, address indexed buyer, uint256 amount);
    event GoodsDispatched(uint256 indexed orderId, address indexed seller);
    event GoodsDelivered(uint256 indexed orderId, uint256 deliveryTimestamp);
    event OrderAccepted(uint256 indexed orderId, address indexed seller, uint256 amount);
    event OrderRejected(uint256 indexed orderId, address indexed buyer, uint256 amount);

    constructor() {
        orderCount = 0;
    }
}   