// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";


contract Emma is Ownable {
    mapping(address => bool) manufacturers;
    mapping(address => Warehouse) warehouses;
    mapping(address => Store) stores;
    mapping(bytes20 => Product) inventory;
    bytes20[] public productIds;
    
    struct Product {
        uint msrp;
        string name;
        address manufacturer;
        string sku;
        bool exists;
    }

    Product nullProduct = Product(0, '', address(0), '', false);

    struct Warehouse {
        string name;
        string physicalAddress;
        bool exists;
    }

    struct Store {
        string name;
        bool exists;
    }
    

    function registerManufacturer() public {
        manufacturers[_msgSender()] = true;
    }

    function isManufacturer(address addr) public view returns (bool) {
        return manufacturers[addr];
    }

    function registerWarehouse(string calldata name, string calldata _physicalAddress) public {
        warehouses[_msgSender()] = Warehouse(name, _physicalAddress, true);
    }

    function isWarehouse(address addr) public view returns (bool) {
        return warehouses[addr].exists;
    }

    function registerStore(string calldata name) public {
        stores[_msgSender()] = Store(name, true);
    }

    function isStore(address addr) public view returns (bool) {
        return stores[addr].exists;
    }

    function addToInventory(
        uint _msrp,
        string calldata _name,
        string calldata _sku)
        public 
        {
        require(isManufacturer(_msgSender()), 'Only a manufacturer can add products to the inventory');
        require(!getProductBySku(_sku).exists, 'Product already exists in inventory');
        bytes20 productId = bytes20(keccak256(abi.encodePacked(_msgSender(), block.timestamp)));
        inventory[productId] = Product({
            msrp: _msrp,
            name: _name,
            manufacturer: _msgSender(),
            sku: _sku,
            exists: true
        });
        productIds.push(productId);
    }

    function getProductBySku(string calldata _sku) public view returns (Product memory) {
        for (uint i=0; i< productIds.length; i++) {
            if (keccak256(abi.encodePacked(inventory[productIds[i]].sku)) == keccak256(abi.encodePacked(_sku))) {
                return inventory[productIds[i]];
            }
        }
        return nullProduct;
    }

    function getProductById(bytes20 _productId) public view returns (Product memory) {
        return inventory[_productId];
    }

    function getProductsByManufacturer(address addr) public view returns (bytes20[] memory) {
        uint numResults;
        for (uint i=0; i<productIds.length; i++) {
            if (inventory[productIds[i]].manufacturer == addr) {
                numResults++;
            }
        }
        bytes20[] memory filteredProductIds = new bytes20[](numResults);
        uint j;
        for (uint i=0; i<productIds.length; i++) {
            if (inventory[productIds[i]].manufacturer == addr) {
                filteredProductIds[j] = productIds[i];
                j++;
            }
        }
        return filteredProductIds;
    }
}