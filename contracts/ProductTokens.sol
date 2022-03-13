// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract ProductTokens is Ownable, ERC1155 {

    constructor() ERC1155("https://my.urls/{id}.json") {}

    function mintProduct(uint256 productId, uint256 amount) public {
        _mint(_msgSender(), productId, amount, "");
    }
}