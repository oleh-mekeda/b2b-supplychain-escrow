// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title B2B Supply Chain Escrow & Product Acceptance
 * @dev Smart contract implementing Seller Offer -> Buyer Acceptance -> Inspection -> Pull-based Settlement.
 */
contract SupplyChainEscrow {

    enum State { 
        Created, 
        FundsDeposited, 
        Dispatched, 
        Delivered, 
        AcceptedAndPaid, 
        RejectedAndRefunded 
    }

    struct EscrowOrder {
        address payable buyer;
        address payable seller;
        address inspector;
        uint256 amount;
        bytes32 itemHash;
        uint256 deliveryDeadline;
        uint256 deliveryTimestamp;
        State state;
        bool isInspected;
    }

    uint256 public orderCount;
    mapping(uint256 => EscrowOrder) public orders;

    event OrderCreated(uint256 indexed orderId, address indexed seller, address indexed buyer, uint256 amount);
    event FundsDeposited(uint256 indexed orderId, address indexed buyer, uint256 amount);
    event GoodsDispatched(uint256 indexed orderId, address indexed seller);
    event GoodsDelivered(uint256 indexed orderId, uint256 deliveryTimestamp);
    event InspectionSubmitted(uint256 indexed orderId, bool passed);
    event OrderAccepted(uint256 indexed orderId, address indexed seller, uint256 amount);
    event OrderRejected(uint256 indexed orderId, address indexed buyer, uint256 amount);

    constructor() {
        orderCount = 0;
    }

    /**
     * @dev Step 1: Seller creates an order offer with specified parameters.
     */
    function createOrder(
        address payable _buyer,
        address _inspector,
        uint256 _amount,
        bytes32 _itemHash,
        uint256 _deliveryDeadline
    ) external returns (uint256) {
        require(_buyer != address(0) && _buyer != msg.sender, "Invalid buyer address");
        require(_inspector != address(0) && _inspector != msg.sender && _inspector != _buyer, "Invalid inspector address");
        require(_amount > 0, "Amount must be greater than zero");
        require(_deliveryDeadline > block.timestamp, "Deadline must be in the future");

        orderCount++;
        orders[orderCount] = EscrowOrder({
            buyer: _buyer,
            seller: payable(msg.sender),
            inspector: _inspector,
            amount: _amount,
            itemHash: _itemHash,
            deliveryDeadline: _deliveryDeadline,
            deliveryTimestamp: 0,
            state: State.Created,
            isInspected: false
        });

        emit OrderCreated(orderCount, msg.sender, _buyer, _amount);
        return orderCount;
    }

    /**
     * @dev Step 2: Buyer deposits funds (accepts seller's offer).
     */
    function depositFunds(uint256 _orderId) external payable {
        EscrowOrder storage order = orders[_orderId];

        require(msg.sender == order.buyer, "Only designated buyer can deposit funds");
        require(order.state == State.Created, "Invalid order state for deposit");
        require(msg.value == order.amount, "Must deposit exact order amount");

        order.state = State.FundsDeposited;
        emit FundsDeposited(_orderId, msg.sender, msg.value);
    }

    /**
     * @dev Step 3: Seller confirms dispatch of goods before deadline.
     */
    function confirmDispatch(uint256 _orderId) external {
        EscrowOrder storage order = orders[_orderId];

        require(msg.sender == order.seller, "Only seller can confirm dispatch");
        require(order.state == State.FundsDeposited, "Invalid order state for dispatch");
        require(block.timestamp <= order.deliveryDeadline, "Delivery deadline has passed");

        order.state = State.Dispatched;
        emit GoodsDispatched(_orderId, msg.sender);
    }

    /**
     * @dev Step 4: Seller confirms physical delivery to buyer's location.
     */
    function confirmDelivery(uint256 _orderId) external {
        EscrowOrder storage order = orders[_orderId];

        require(msg.sender == order.seller, "Only seller can confirm delivery");
        require(order.state == State.Dispatched, "Invalid order state for delivery");

        order.state = State.Delivered;
        order.deliveryTimestamp = block.timestamp;
        emit GoodsDelivered(_orderId, block.timestamp);
    }

    /**
     * @dev Step 5: Independent inspector submits inspection report (true/false).
     */
    function submitInspectionReport(uint256 _orderId, bool _passed) external {
        EscrowOrder storage order = orders[_orderId];

        require(msg.sender == order.inspector, "Only inspector can submit report");
        require(order.state == State.Delivered, "Goods must be delivered first");

        order.isInspected = _passed;
        emit InspectionSubmitted(_orderId, _passed);
    }

    /**
     * @dev Step 6a: Seller claims payment if inspection passed (isInspected == true).
     */
    function claimPayment(uint256 _orderId) external {
        EscrowOrder storage order = orders[_orderId];

        require(msg.sender == order.seller, "Only seller can claim payment");
        require(order.state == State.Delivered, "Order must be in Delivered state");
        require(order.isInspected, "Inspection must pass before payment");

        order.state = State.AcceptedAndPaid;

        (bool success, ) = order.seller.call{value: order.amount}("");
        require(success, "Payment transfer failed");

        emit OrderAccepted(_orderId, order.seller, order.amount);
    }

    /**
     * @dev Step 6b: Buyer claims refund if delivery deadline passed OR inspection failed.
     */
    function claimRefund(uint256 _orderId) external {
        EscrowOrder storage order = orders[_orderId];

        require(msg.sender == order.buyer, "Only buyer can claim refund");

        bool deadlinePassed = (order.state == State.FundsDeposited && block.timestamp > order.deliveryDeadline);
        bool inspectionFailed = (order.state == State.Delivered && !order.isInspected);

        require(deadlinePassed || inspectionFailed, "Refund conditions not met");

        order.state = State.RejectedAndRefunded;

        (bool success, ) = order.buyer.call{value: order.amount}("");
        require(success, "Refund transfer failed");

        emit OrderRejected(_orderId, order.buyer, order.amount);
    }
}