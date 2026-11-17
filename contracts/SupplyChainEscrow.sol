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

/**
     * @dev Initializes a new escrow order.
     */
    function createOrder(
        address payable _seller,
        address _inspector,
        bytes32 _itemHash,
        uint256 _deliveryDeadline,
        uint256 _inspectionWindow
    ) external returns (uint256) {
        require(_seller != address(0), "Invalid seller address");
        require(_inspector != address(0), "Invalid inspector address");
        require(_deliveryDeadline > block.timestamp, "Deadline must be in the future");

        orderCount++;
        orders[orderCount] = EscrowOrder({
            buyer: payable(msg.sender),
            seller: _seller,
            inspector: _inspector,
            amount: 0,
            itemHash: _itemHash,
            deliveryDeadline: _deliveryDeadline,
            deliveryTimestamp: 0,
            inspectionWindow: _inspectionWindow,
            state: State.Created,
            isInspected: false
        });

        emit OrderCreated(orderCount, msg.sender, _seller, _inspector, 0);
        return orderCount;
    }

    /**
     * @dev Deposits funds into escrow vault for a specific order.
     */
    function depositFunds(uint256 _orderId) external payable {
        EscrowOrder storage order = orders[_orderId];

        require(msg.sender == order.buyer, "Only buyer can deposit funds");
        require(order.state == State.Created, "Invalid order state for deposit");
        require(msg.value > 0, "Deposit amount must be greater than zero");

        order.amount = msg.value;
        order.state = State.FundsDeposited;

        emit FundsDeposited(_orderId, msg.sender, msg.value);
    }
}