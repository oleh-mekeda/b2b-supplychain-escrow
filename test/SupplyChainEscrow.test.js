const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("SupplyChainEscrow Smart Contract Tests", function () {
    let Escrow, escrow;
    let seller, buyer, inspector, attacker;
    const orderAmount = ethers.parseEther("1.0");
    const itemHash = ethers.id("PROFORMA_INVOICE_SPEC_V1");
    let deliveryDeadline;

    beforeEach(async function () {
        [seller, buyer, inspector, attacker] = await ethers.getSigners();
        Escrow = await ethers.getContractFactory("SupplyChainEscrow");
        
        const currentBlock = await ethers.provider.getBlock("latest");
        deliveryDeadline = currentBlock.timestamp + 7 * 24 * 60 * 60;

        escrow = await Escrow.deploy();
        await escrow.waitForDeployment();
    });

    describe("1. Order Creation & Deposit (Happy & Edge Cases)", function () {
        it("Should allow seller to create order successfully", async function () {
            await expect(escrow.connect(seller).createOrder(buyer.address, inspector.address, orderAmount, itemHash, deliveryDeadline))
                .to.emit(escrow, "OrderCreated");
            
            const order = await escrow.orders(1);
            expect(order.seller).to.equal(seller.address);
            expect(order.amount).to.equal(orderAmount);
            expect(order.state).to.equal(0); // State.Created
        });

        it("Should revert if buyer deposits incorrect ETH amount", async function () {
            await escrow.connect(seller).createOrder(buyer.address, inspector.address, orderAmount, itemHash, deliveryDeadline);
            
            const wrongAmount = ethers.parseEther("0.5");
            await expect(escrow.connect(buyer).depositFunds(1, { value: wrongAmount }))
                .to.be.revertedWith("Must deposit exact order amount");
        });

        it("Should transition state to FundsDeposited on exact deposit", async function () {
            await escrow.connect(seller).createOrder(buyer.address, inspector.address, orderAmount, itemHash, deliveryDeadline);
            
            await escrow.connect(buyer).depositFunds(1, { value: orderAmount });
            const order = await escrow.orders(1);
            expect(order.state).to.equal(1); // State.FundsDeposited
        });
    });

    describe("2. Access Control & Execution Sequence", function () {
        beforeEach(async function () {
            await escrow.connect(seller).createOrder(buyer.address, inspector.address, orderAmount, itemHash, deliveryDeadline);
            await escrow.connect(buyer).depositFunds(1, { value: orderAmount });
        });

        it("Should revert if unauthorized party attempts to confirm dispatch", async function () {
            await expect(escrow.connect(attacker).confirmDispatch(1))
                .to.be.revertedWith("Only seller can confirm dispatch");
        });

        it("Should allow seller to confirm dispatch and delivery", async function () {
            await escrow.connect(seller).confirmDispatch(1);
            let order = await escrow.orders(1);
            expect(order.state).to.equal(2); // State.Dispatched

            await escrow.connect(seller).confirmDelivery(1);
            order = await escrow.orders(1);
            expect(order.state).to.equal(3); // State.Delivered
        });
    });

    describe("3. Inspection & Settlement (Pull Payments)", function () {
        beforeEach(async function () {
            await escrow.connect(seller).createOrder(buyer.address, inspector.address, orderAmount, itemHash, deliveryDeadline);
            await escrow.connect(buyer).depositFunds(1, { value: orderAmount });
            await escrow.connect(seller).confirmDispatch(1);
            await escrow.connect(seller).confirmDelivery(1);
        });

        it("Should allow seller to claim payment after positive inspection report", async function () {
            await escrow.connect(inspector).submitInspectionReport(1, true);

            const initialBalance = await ethers.provider.getBalance(seller.address);
            await escrow.connect(seller).claimPayment(1);
            const finalBalance = await ethers.provider.getBalance(seller.address);

            expect(finalBalance).to.be.gt(initialBalance);

            const order = await escrow.orders(1);
            expect(order.state).to.equal(4); // State.AcceptedAndPaid
        });

        it("Should allow buyer to claim refund after negative inspection report", async function () {
            await escrow.connect(inspector).submitInspectionReport(1, false);

            const initialBalance = await ethers.provider.getBalance(buyer.address);
            await escrow.connect(buyer).claimRefund(1);
            const finalBalance = await ethers.provider.getBalance(buyer.address);

            expect(finalBalance).to.be.gt(initialBalance);

            const order = await escrow.orders(1);
            expect(order.state).to.equal(5); // State.RejectedAndRefunded
        });
    });
});