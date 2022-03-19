// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./ERC1155Receiver.sol";
import "./ProductTokens.sol";
import "./ProductReceiptTokens.sol";
import "./USDC.sol";
import "./EmmaStructs.sol";

contract Emma is Ownable, ERC1155Receiver {
    address productTokensContract;
    address productReceiptTokensContract;
    address usdcTokensContract;
    ProductTokens productTokens;
    ProductReceiptTokens productReceiptTokens;
    USDC usdc;
    mapping(address => EmmaStructs.Manufacturer) public manufacturers;
    mapping(address => EmmaStructs.Warehouse) public warehouses;
    // mapping(address => EmmaStructs.Store) public stores;
    mapping(uint256 => EmmaStructs.Product) public catalog;
    mapping(uint256 => uint256) public claimableTokens;
    uint256 latestProductId = 1;
    uint256 constant NULL_PRODUCT = 0;
    uint256 protocolFeePercentage = 10; // 10% percent

    constructor(address _productTokensContract, address _productReceiptTokensContract, address _usdcTokensContract) {
        productTokensContract = _productTokensContract;
        productTokens = ProductTokens(productTokensContract);
        productReceiptTokensContract = _productReceiptTokensContract;
        productReceiptTokens = ProductReceiptTokens(productReceiptTokensContract);
        usdcTokensContract = _usdcTokensContract;
        usdc = USDC(usdcTokensContract);
    }

    function registerManufacturer() public {
        manufacturers[_msgSender()].exists = true;
    }

    function isManufacturer(address addr) public view returns (bool) {
        return manufacturers[addr].exists;
    }

    function registerWarehouse(string calldata name, string calldata _physicalAddress) public {
        warehouses[_msgSender()] = EmmaStructs.Warehouse(name, _physicalAddress, true);
    }

    function isWarehouse(address addr) public view returns (bool) {
        return warehouses[addr].exists;
    }

    // function registerStore() public {
    //     stores[_msgSender()].exists = true;
    // }

    // function isStore(address addr) public view returns (bool) {
    //     return stores[addr].exists;
    // }

    function _calculateProtocolFee(uint256 amount) internal view returns (uint256) {
        return amount * protocolFeePercentage / 100;
    }

    function addProductToCatalog(
        uint _manufacturerPrice,
        string calldata _name,
        string calldata _sku)
        public
        {
        require(isManufacturer(_msgSender()), 'Only a manufacturer can add products to the catalog');
        require(getProductBySku(_sku) == NULL_PRODUCT, 'Product already exists in catalog');
        catalog[latestProductId] = EmmaStructs.Product({
            manufacturerPrice: _manufacturerPrice,
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

    function getProductById(uint256 _productId) public view returns (EmmaStructs.Product memory) {
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
        EmmaStructs.Product memory product = getProductById(productId);
        require(product.manufacturer == _msgSender(), 'Only the manufacturer can add product to the inventory');
        productTokens.mintProduct(productId, amount);
        productReceiptTokens.mintProduct(productId, amount);
        productReceiptTokens.transfer(_msgSender(), productId, amount);
    }

    function purchaseProduct(string calldata sku, uint256 price, uint256 amount) public {
        uint256 productId = getProductBySku(sku);
        EmmaStructs.Product memory product = getProductById(productId);
        require(price >= product.manufacturerPrice);
        usdc.transferFrom(_msgSender(), address(this), price * amount);
        productTokens.transfer(_msgSender(), productId, amount);
        claimableTokens[productId] += amount;
    }

    function claimProfits(string calldata sku) public {
        uint256 productId = getProductBySku(sku);
        require(productReceiptTokens.balanceOf(_msgSender(), productId) > claimableTokens[productId], "Nothing to claim");
        EmmaStructs.Product memory product = getProductById(productId);
        uint256 salesProfit = product.manufacturerPrice * claimableTokens[productId];
        usdc.transfer(_msgSender(), salesProfit - _calculateProtocolFee(salesProfit));
        productReceiptTokens.burn(_msgSender(), productId, claimableTokens[productId]);
        claimableTokens[productId] = 0;
    }

}