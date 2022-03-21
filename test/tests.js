const { assert } = require('chai');

describe("Emma", () => {
    let manufacturer;
    let nonManufacturer;
    let warehouse;
    let store;
    let customer;
    before(async () => {
        const ProductTokens = await ethers.getContractFactory("ProductTokens");
        productTokens = await ProductTokens.deploy();
        await productTokens.deployed()
        const ProductReceiptTokens = await ethers.getContractFactory("ProductReceiptTokens");
        productReceiptTokens = await ProductReceiptTokens.deploy();
        await productReceiptTokens.deployed()
        const USDC = await ethers.getContractFactory("USDC");
        usdc = await USDC.deploy();
        await usdc.deployed();
        const Emma = await ethers.getContractFactory("Emma");
        emma = await Emma.deploy(productTokens.address, productReceiptTokens.address, usdc.address);
        await emma.deployed();
        const Store = await ethers.getContractFactory("Store");
        store = await Store.deploy(emma.address, productTokens.address, usdc.address);
        await store.deployed();
        deployer = await ethers.provider.getSigner(0);
        manufacturer = await ethers.provider.getSigner(1);
        warehouse = await ethers.provider.getSigner(2);
        nonManufacturer = await ethers.provider.getSigner(3);
        customer = await ethers.provider.getSigner(4);
    });
    describe("Adding stakeholders", () => {
        it("should add a new manufacturer", async () => {
            await emma.connect(manufacturer).registerManufacturer();
            assert(await emma.isManufacturer(manufacturer.getAddress()));
        });
        it("should add a new warehouse", async () => {
            await emma.connect(warehouse).registerWarehouse('My Warehouse', 'My Physical Address');
            assert(await emma.isWarehouse(warehouse.getAddress()));
        });
    });
    describe('Adding and retrieving products to/from the catalog', () => {
        it('should add a new product to the catalog', async () => {
            const sku = 'MILK';
            const name = 'Gallon of milk';
            const manufacturerPrice = 2;
            await emma.connect(manufacturer).addProductToCatalog(manufacturerPrice, name, sku);
            const productId = await emma.getProductBySku(sku);
            const product = await emma.getProductById(productId);
            assert.equal(product.manufacturerPrice, manufacturerPrice);
            assert.equal(product.name, name);
            assert.equal(product.manufacturer, await manufacturer.getAddress());
        });
        it('should prevent a non manufacturer from adding a product to the catalog', async () => {
            let ex;
            try {
                await emma.connect(nonManufacturer).addProductToCatalog(0, 'dummy', 'dummy');
            }
            catch (_ex) {
                ex = _ex;
            }
            assert(ex, 'Only a manufacturer can add products to the catalog. Expected transaction to revert!');
        });
        it('should prevent from adding a product that already exists', async () => {
            let ex;
            try {
                await emma.connect(manufacturer).addProductToCatalog(0, 'dummy', 'MILK');
            }
            catch (_ex) {
                ex = _ex;
            }
            assert(ex, 'Product already exists in catalog. Expected transaction to revert!');
        });
        it('should retrieve products by manufacturer and by product id', async () => {
            await emma.connect(manufacturer).addProductToCatalog(0, 'Dummy 1', 'DUMMY-1');
            await emma.connect(manufacturer).addProductToCatalog(0, 'Dummy 1', 'DUMMY-2');
            let productIds = await emma.getProductsByManufacturer(manufacturer.getAddress());
            let products = [];
            for (let productId of productIds) {
                products.push(await emma.getProductById(productId));
            }
            assert.sameMembers(products.map(x => x.sku), ['MILK', 'DUMMY-1', 'DUMMY-2']);
        });
    });
    describe('Adding products to the inventory', () => {
        let shipmentId;
        before(async () => {
            await emma.connect(manufacturer).addProductToInventory('MILK', 100, warehouse.getAddress());
            const manuf = await emma.getManufacturer(manufacturer.getAddress());
            shipmentId = manuf.pendingShipments[0];
        });
        describe('After adding a product to the inventory', () => {
            it('should increase the amount of milk tokens in the inventory', async () => {
                const productId = await emma.getProductBySku('MILK');
                const balance = await productTokens.balanceOf(emma.address, productId);
                assert.equal(balance.toString(), "100");
            });
            it('should create a shipment from the manufacturer to the warehouse', async () => {
                const shipments = await emma.getShipment(shipmentId);
                assert.equal(shipments.from, await manufacturer.getAddress());
                assert.equal(shipments.to, await warehouse.getAddress());
            });
            it('should prevent the manufacturer from claiming their product receipt tokens before the warehouse confirms the shipment has been received', async () => {
                let ex;
                try {
                    await emma.connect(manufacturer).claimProductReceiptTokens(shipmentId);
                }
                catch (_ex) {
                    ex = _ex;
                }
                assert(ex, "Shipment receipt hasn't been confirmed by the warehouse. Expected transaction to revert!");
            });
        });
        
    });
    describe('Claiming product receipt tokens after a shipment has been confirmed by the warehouse', () => {
        before(async () => {
            const wh = await emma.getWarehouse(warehouse.getAddress());
            shipmentId = wh.pendingShipments[0];
            await emma.connect(warehouse).confirmProductReceiptbyWarehouse(shipmentId);
        });
        describe('After the warehouse confirms the receipt of the product', () => {
            it("should allow the manufacturer to claim their product receipt tokens", async () => {
                await emma.connect(manufacturer).claimProductReceiptTokens(shipmentId);
                const productId = await emma.getProductBySku('MILK');
                const balance = await productReceiptTokens.balanceOf(manufacturer.getAddress(), productId);
                assert.equal(balance.toString(), "100");
            });
        });
        
    });
    describe('Purchasing products directly from Emma', () => {
        before(async () => {
            await usdc.transfer(customer.getAddress(), 1000);
            await usdc.connect(customer).approve(emma.address, 1000);
            await emma.connect(customer).purchaseProduct('MILK', 2, 5);
        });
        describe('After purchasing 5 gallons of milk at 2 USDC each', () => {
            it("should exist 990 USDC in the customer's wallet", async () => {
                const usdcBalance = await usdc.balanceOf(customer.getAddress());
                assert.equal(usdcBalance.toString(), "990");
            });
            it("should exist 5 milk tokens in the customer's wallet", async () => {
                const productId = await emma.getProductBySku('MILK');
                const milkBalance = await productTokens.balanceOf(customer.getAddress(), productId);
                assert.equal(milkBalance.toString(), "5");
            });
            it("should exist 10 USDC in the Emma contract", async () => {
                const usdcBalance = await usdc.balanceOf(emma.address);
                assert.equal(usdcBalance.toString(), "10");
            });
            it("should exist 95 milk tokens in the Emma contract", async () => {
                const productId = await emma.getProductBySku('MILK');
                const milkBalance = await productTokens.balanceOf(emma.address, productId);
                assert.equal(milkBalance.toString(), "95");
            });
        });
        describe('When trying to buy 100 gallons of milk', () => {
            it("should revert the transaction because there are not enough milk tokens", async () => {
                let ex;
                try {
                    await emma.connect(customer).purchaseProduct('MILK', 2, 100);
                }
                catch (_ex) {
                    ex = _ex;
                }
                assert(ex, 'There is not enough milk left in the inventory. Expected transaction to revert!');
            });
        });
    });
    describe('Purchasing products through a store', () => {
        before(async () => {
            await usdc.connect(customer).approve(store.address, 1000);
            await store.connect(customer).purchaseProduct('MILK', 5);
        });
        describe('After purchasing 5 gallons of milk at 4 USDC each (2 USDC + 2 USDC markup)', () => {
            it("should exist 970 USDC in the customer's wallet", async () => {
                const usdcBalance = await usdc.balanceOf(customer.getAddress());
                assert.equal(usdcBalance.toString(), "970");
            });
            it("should exist 10 milk tokens in the customer's wallet", async () => {
                const productId = await emma.getProductBySku('MILK');
                const milkBalance = await productTokens.balanceOf(customer.getAddress(), productId);
                assert.equal(milkBalance.toString(), "10");
            });
            it("should exist 20 USDC in the Emma contract", async () => {
                const usdcBalance = await usdc.balanceOf(emma.address);
                assert.equal(usdcBalance.toString(), "20");
            });
            it("should exist 90 milk tokens in the Emma contract", async () => {
                const productId = await emma.getProductBySku('MILK');
                const milkBalance = await productTokens.balanceOf(emma.address, productId);
                assert.equal(milkBalance.toString(), "90");
            });
            it("should exist 10 USDC in the Store contract (this is the store's profit)", async () => {
                const usdcBalance = await usdc.balanceOf(store.address);
                assert.equal(usdcBalance.toString(), "10");
            });
            it("should exist 0 milk tokens in the Store contract", async () => {
                const productId = await emma.getProductBySku('MILK');
                const milkBalance = await productTokens.balanceOf(store.address, productId);
                assert.equal(milkBalance.toString(), "0");
            });
        });
    });
    describe('Claiming profits by the manufacturer', () => {
        before(async () => {
            await productReceiptTokens.connect(manufacturer).setApprovalForAll(emma.address, true);
            await emma.connect(manufacturer).claimProfits('MILK');
        });
        describe('After claiming profits for milk sales', () => {
            it("should exist 90 milk receipt tokens in the Manufacturer's wallet", async () => {
                const productId = await emma.getProductBySku('MILK');
                const milkReceiptBalance = await productReceiptTokens.balanceOf(manufacturer.getAddress(), productId);
                assert.equal(milkReceiptBalance.toString(), "90");
            });
            it("should exist 18 USDC in the Manufacturer's wallet (sales of 20 USDC minus the 10% protocol fee)", async () => {
                const usdcBalance = await usdc.balanceOf(manufacturer.getAddress());
                assert.equal(usdcBalance.toString(), "18");
            });
            it("should exist 2 USDC in the Emma contract (the 5% protocol fee + the 5% unclaimed storage fee)", async () => {
                const usdcBalance = await usdc.balanceOf(emma.address);
                assert.equal(usdcBalance.toString(), "2");
            });
            it("should be no claimable milk tokens on the Emma contract", async () => {
                const productId = await emma.getProductBySku('MILK');
                const claimableTokenAmount = await emma.claimableTokens(productId);
                assert.equal(claimableTokenAmount.toString(), "0");
            });
        });
    });
    describe('Exchange product tokens for physical products', () => {
        before(async () => {
            await productTokens.connect(customer).setApprovalForAll(emma.address, true);
            await emma.connect(customer).exchangeTokensForProduct(warehouse.getAddress());
        });
        describe('After the customer exchanges their product tokens', () => {
            it("should exist 0 milk tokens in the customer's wallet", async () => {
                const productId = await emma.getProductBySku('MILK');
                const milkBalance = await productTokens.balanceOf(customer.getAddress(), productId);
                assert.equal(milkBalance.toString(), "0");
            });
            it("should exist 1 USDC in claimable storage fees for the warehouse", async () => {
                const wh = await emma.getWarehouse(warehouse.getAddress());
                assert.equal(wh.claimableFees.toString(), "1");
            });
        });
        describe('After the warehouse claims their storage fees', () => {
            it("should exist 1 USDC in the warehouse's wallet", async () => {
                await emma.connect(warehouse).claimStorageFee();
                const usdcBalance = await usdc.balanceOf(warehouse.getAddress());
                assert.equal(usdcBalance.toString(), "1");
            });
        });
    });
    
});


