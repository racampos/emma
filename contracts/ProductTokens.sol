// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";

contract ProductTokens is Ownable, ERC1155Burnable {

    constructor() ERC1155("https://my.urls/{id}.json") {}

    function mintProduct(uint256 productId, uint256 amount) public {
        _mint(_msgSender(), productId, amount, "");
    }

    function transfer(address to, uint256 productId, uint256 amount) public {
        _safeTransferFrom(_msgSender(), to, productId, amount, "");
        
    }
}