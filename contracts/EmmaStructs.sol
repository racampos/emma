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
        uint256[] pendingShipments;
    }

    struct Warehouse {
        string name;
        string physicalAddress;
        uint256[] pendingShipments;
        uint256 claimableFees;
        bool exists;
    }

    struct Store {
        uint256 balance;
        bool exists;
    }

    struct Shipment {
        address from;
        address to;
        uint256[] productIds;
        uint256[] amounts;
        bool received;
    }
}


    