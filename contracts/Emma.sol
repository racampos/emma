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
    uint256 protocolFeePercentage = 5;
    uint256 warehouseFeePercentage = 5;
    EmmaStructs.Shipment[] public shipments;

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

    function registerWarehouse(string calldata _name, string calldata _physicalAddress) public {
        warehouses[_msgSender()].exists = true;
        warehouses[_msgSender()].name = _name;
        warehouses[_msgSender()].physicalAddress = _physicalAddress;
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

    function _calculateFee(uint256 feePercentage, uint256 amount) internal pure returns (uint256) {
        return amount * feePercentage / 100;
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

    function registerBatchShipment(address _from, address _to, uint256[] memory _productIds, uint256[] memory _amounts) public returns (uint256) {
        EmmaStructs.Shipment memory shipment = EmmaStructs.Shipment({
            from: _from,
            to: _to,
            productIds: _productIds,
            amounts: _amounts,
            received: false
        });
        shipments.push(shipment);
        return shipments.length - 1;
    }

    function registerSingleShipment(address _from, address _to, uint256 _productId, uint256 _amount) public returns (uint256) {
        uint256[] memory productIds = new uint256[](1);
        uint256[] memory amounts = new uint256[](1);
        productIds[0] = _productId;
        amounts[0] = _amount;
        return registerBatchShipment(_from, _to, productIds, amounts);
    }

    function addProductToInventory(string calldata _sku, uint256 amount, address _warehouse) public {
        uint256 productId = getProductBySku(_sku);
        require(productId != NULL_PRODUCT, 'Product not in catalog');
        EmmaStructs.Product memory product = getProductById(productId);
        require(product.manufacturer == _msgSender(), 'Only the manufacturer can add product to the inventory');
        productTokens.mintProduct(productId, amount);
        productReceiptTokens.mintProduct(productId, amount);
        uint256 shipmentId = registerSingleShipment(_msgSender(), _warehouse, productId, amount);
        warehouses[_warehouse].pendingShipments.push(shipmentId);
        manufacturers[_msgSender()].pendingShipments.push(shipmentId);
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
        uint256 fees = _calculateFee(protocolFeePercentage, salesProfit) + _calculateFee(warehouseFeePercentage, salesProfit);
        usdc.transfer(_msgSender(), salesProfit - fees);
        productReceiptTokens.burn(_msgSender(), productId, claimableTokens[productId]);
        claimableTokens[productId] = 0;
    }

    function confirmShipmentReceipt(address receiver, uint256 shipmentId) internal {
        require(shipments[shipmentId].to == receiver, "Only the receiver can confirm a shipment.");
        shipments[shipmentId].received = true;
    }

    function confirmProductReceiptbyWarehouse(uint256 shipmentId) public {
        require(isWarehouse(_msgSender()), "Only a warehouse can confirm a product shipment");
        confirmShipmentReceipt(_msgSender(), shipmentId);
    }

    function claimProductReceiptTokens(uint256 shipmentId) public {
        EmmaStructs.Shipment memory shipment = shipments[shipmentId];
        require(_msgSender() == shipment.from, "Only the manufacturer that sent the product can claim the receipt tokens");
        require(shipment.received);
        for (uint i=0; i<shipment.productIds.length; i++) {
            productReceiptTokens.transfer(_msgSender(), shipment.productIds[i], shipment.amounts[i]);
        }
    }

    function claimStorageFee() public {
        require(isWarehouse(_msgSender()), 'Only warehouses can claim storage fees.');
        uint256 feesToClaim = warehouses[_msgSender()].claimableFees;
        require(feesToClaim > 0, 'Nothing to claim.');
        usdc.transfer(_msgSender(), feesToClaim);
    }

    function exchangeTokensForProduct(address _warehouse) public {
        bool hasProductTokens;
        for (uint i=1; i<=latestProductId; i++) {
            if (productTokens.balanceOf(_msgSender(), i) > 0) {
                hasProductTokens = true;
            }
        }
        require(hasProductTokens, 'No product tokens in wallet to exchange for');
        uint256 warehouseFee;
        for (uint productId=1; productId<=latestProductId; productId++) {
            uint256 tokenBalance = productTokens.balanceOf(_msgSender(), productId);
            if (tokenBalance > 0) {
                EmmaStructs.Product memory product = getProductById(productId);
                warehouseFee += _calculateFee(warehouseFeePercentage, product.manufacturerPrice * tokenBalance);
                productTokens.burn(_msgSender(), productId, tokenBalance);
            }
        }
        warehouses[_warehouse].claimableFees = warehouseFee;        
    }

    function getShipment(uint256 shipmentId) public view returns (EmmaStructs.Shipment memory) {
        return shipments[shipmentId];
    }

    function getManufacturer(address addr) public view returns (EmmaStructs.Manufacturer memory) {
        return manufacturers[addr];
    }

    function getWarehouse(address addr) public view returns (EmmaStructs.Warehouse memory) {
        return warehouses[addr];
    }
        
}