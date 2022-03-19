// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library EmmaStructs {

    struct Product {
        uint manufacturerPrice;
        string name;
        address manufacturer;
        string sku;
        bool exists;
    }

    struct Manufacturer {
        uint256 balance;
        bool exists;
    }

    struct Warehouse {
        string name;
        string physicalAddress;
        bool exists;
    }

    struct Store {
        uint256 balance;
        bool exists;
    }
}


    