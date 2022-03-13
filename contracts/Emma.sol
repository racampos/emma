// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./ERC1155Receiver.sol";
import "./ProductTokens.sol";

contract Emma is Ownable, ERC1155Receiver {
    address productTokensContract;
    mapping(address => bool) public manufacturers;
    mapping(address => Warehouse) public warehouses;
    mapping(address => Store) public stores;
    mapping(uint256 => Product) public catalog;
    uint256 latestProductId = 1;
    uint256 constant NULL_PRODUCT = 0;
    mapping(uint256 => uint) public inventory;
    
    struct Product {
        uint msrp;
        string name;
        address manufacturer;
        string sku;
        bool exists;
    }

    struct Warehouse {
        string name;
        string physicalAddress;
        bool exists;
    }

    struct Store {
        string name;
        bool exists;
    }

    constructor(address _productTokensContract) {
        productTokensContract = _productTokensContract;
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

    function addProductToCatalog(
        uint _msrp,
        string calldata _name,
        string calldata _sku)
        public
        {
        require(isManufacturer(_msgSender()), 'Only a manufacturer can add products to the catalog');
        require(getProductBySku(_sku) == NULL_PRODUCT, 'Product already exists in catalog');
        catalog[latestProductId] = Product({
            msrp: _msrp,
            name: _name,
            manufacturer: _msgSender(),
            sku: _sku,
            exists: true
        });
        latestProductId++;
    }

    function getProductBySku(string calldata _sku) public view returns (uint256) {
        for (uint i=0; i< latestProductId; i++) {
            if (keccak256(abi.encodePacked(catalog[i].sku)) == keccak256(abi.encodePacked(_sku))) {
                return i;
            }
        }
        return NULL_PRODUCT;
    }

    function getProductById(uint256 _productId) public view returns (Product memory) {
        return catalog[_productId];
    }

    function getProductsByManufacturer(address addr) public view returns (uint256[] memory) {
        uint numResults;
        for (uint i=0; i<latestProductId; i++) {
            if (catalog[i].manufacturer == addr) {
                numResults++;
            }
        }
        uint256[] memory filteredProductIds = new uint256[](numResults);
        uint j;
        for (uint i=0; i<latestProductId; i++) {
            if (catalog[i].manufacturer == addr) {
                filteredProductIds[j] = i;
                j++;
            }
        }
        return filteredProductIds;
    }

    function addProductToInventory(string calldata _sku, uint256 amount) public {
        uint256 productId = getProductBySku(_sku);
        require(productId != NULL_PRODUCT, 'Product not in catalog');
        Product memory product = getProductById(productId);
        require(product.manufacturer == _msgSender(), 'Only the manufacturer can add product to the inventory');
        // inventory[productId] += amount; 
        ProductTokens productTokens = ProductTokens(productTokensContract);
        productTokens.mintProduct(productId, amount);
    }

    // TODO
    // Delete products
    // Delete manufacturers, warehouses, stores
}