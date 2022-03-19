// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC1155Receiver.sol";
import "./Emma.sol";
import "./EmmaStructs.sol";
import "./ProductTokens.sol";
import "./USDC.sol";

contract Store is Ownable, ERC1155Receiver {
    address emmaContract;
    Emma emma;
    address productTokensContract;
    ProductTokens productTokens;
    address usdcTokensContract;
    USDC usdc;
    uint256 markup = 2;

    constructor(address _emmaContract, address _productTokensContract, address _usdcTokensContract) {
        emmaContract = _emmaContract;
        emma = Emma(emmaContract);
        productTokensContract = _productTokensContract;
        productTokens = ProductTokens(productTokensContract);
        usdcTokensContract = _usdcTokensContract;
        usdc = USDC(usdcTokensContract);
        usdc.approve(emmaContract, 2**256 - 1);
    }

    function purchaseProduct(string calldata sku, uint256 amount) public {
        uint256 productId = emma.getProductBySku(sku);
        EmmaStructs.Product memory product = emma.getProductById(productId);
        usdc.transferFrom(_msgSender(), address(this), amount * (product.manufacturerPrice * markup));
        emma.purchaseProduct(sku, product.manufacturerPrice, amount);
        productTokens.transfer(_msgSender(), productId, amount);
    }

}