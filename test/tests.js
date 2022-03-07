const { assert } = require('chai');

describe("Setting up the contracts", () => {
    let manufacturer;
    let nonManufacturer;
    let warehouse;
    let store;
    before(async () => {
        const Emma = await ethers.getContractFactory("Emma");
        contract = await Emma.deploy();
        await contract.deployed();
        manufacturer = await ethers.provider.getSigner(1);
        warehouse = await ethers.provider.getSigner(2);
        nonManufacturer = await ethers.provider.getSigner(3);
        store = await ethers.provider.getSigner(4);
    });
    describe("Adding stakeholders", () => {
        it("should add a new manufacturer", async () => {
            await contract.connect(manufacturer).registerManufacturer();
            assert(await contract.isManufacturer(manufacturer.getAddress()));
        });
        it("should add a new warehouse", async () => {
            await contract.connect(warehouse).registerWarehouse('My Warehouse', 'My Physical Address');
            assert(await contract.isWarehouse(warehouse.getAddress()));
        });
        it("should add a new store", async () => {
            await contract.connect(store).registerStore('My Store');
            assert(await contract.isStore(store.getAddress()));
        });
    });
    describe('Adding a new product', () => {
        it('should add a new product to the inventory', async () => {
            const sku = 'EGG-12';
            const name = 'Dozen eggs';
            const msrp = 2;
            await contract.connect(manufacturer).addToInventory(msrp, name, sku);
            const product = await contract.getProductBySku(sku);
            assert.equal(product.msrp, msrp);
            assert.equal(product.name, name);
            assert.equal(product.manufacturer, await manufacturer.getAddress());
        });
        it('should prevent a non manufacturer from adding a product to the inventory', async () => {
            let ex;
            try {
                await contract.connect(nonManufacturer).addToInventory(0, 'dummy', 'dummy');
            }
            catch (_ex) {
                ex = _ex;
            }
            assert(ex, 'Only a manufacturer can add products to the inventory. Expected transaction to revert!');
        });
        it('should prevent from adding a product that already exists', async () => {
            let ex;
            try {
                await contract.connect(manufacturer).addToInventory(0, 'dummy', 'EGG-12');
            }
            catch (_ex) {
                ex = _ex;
            }
            assert(ex, 'Product already exists in inventory. Expected transaction to revert!');
        });
        it('should retrieve products by manufacturer and by product id', async () => {
            await contract.connect(manufacturer).addToInventory(0, 'Dummy 1', 'DUMMY-1');
            await contract.connect(manufacturer).addToInventory(0, 'Dummy 1', 'DUMMY-2');
            let productIds = await contract.getProductsByManufacturer(manufacturer.getAddress());
            let products = [];
            for (let productId of productIds) {
                products.push(await contract.getProductById(productId));
            }
            assert.sameMembers(products.map(x => x.sku), ['EGG-12', 'DUMMY-1', 'DUMMY-2']);
        });
    });
});
