# Emma: A decentralized marketplace for tokenized products and services

## The Problem

The problem we're trying to solve is twofold:

1. Currently, the only way for producers and manufacturers to be able to sell their products to end customers is through major retail chains, such as supermarkets. These chains take advantage of their privileged position to squeeze profits out of the producers.
2. The retail industry is very capital-intensive, and so there is a huge barrier to entry for new players, especially smaller ones. This in turn causes the market to be owned by very few large players, usually national and global chains.

## The Proposed Solution

Our aim is to allow producers and manufacturers of goods and services to tokenize their products and list them for sale in a decentralized marketplace.
Following are the main features of the proposed solution:
* Products are tokenized using non-fungible tokens (NFTs), according to the EIP-1155 Multi Token Standard.
* Customers can purchase products by interacting with a store, which is just another smart contract that intermediates between the end customer and the decentralized marketplace.
* Anyone can set up a store and there are no assumptions as to how they operate or how much they charge for their services.
* The inventory of products resides in the decentralized marketplace and thus is shared across all the stores. 
* After making a purchase, the NFTs representing the products are transferred to the customer's wallet. The NFTs can then be redeemed for the real products at any time. Once the redemption takes place, the corresponding NFTs are burned.

## Market Participants

![Market Participants](/docs/market_participants.png)

## Nomenclature

![Nomenclature](/docs/nomenclature.png)

## Product Supply Workflow

### Workflow protagonists:

* **Manufacturer**: Tokenizes their product and sends it to the warehouse to be stored.
* **Warehouse**: Receives and stores the products.
* **Emma**: Mints product tokens (PTs) and product receipt tokens (PRTs).

### Workflow:
1. The manufacturer adds their product to the catalog. For this, they provide an SKU, a name and a reference price.

![Product Supply Workflow 1](/docs/psw1.png)

2. The manufacturer adds product to the inventory by minting Product Tokens (PTs) that represent those products. At the same time, they send the physical product to one or more warehouses.
3. Product Receipt Tokens (PRTs) are also minted to act as a receipt for the manufacturer. PRTs are kept in escrow inside the Emma contract until the warehouse confirms receipt of the shipment.

![Product Supply Workflow 2](/docs/psw2.png)

4. Once the shipment arrives to the warehouse, they confirm the receipt.
5. The manufacturer claims their Product Receipt Tokens and keeps them in their wallet.

![Product Supply Workflow 3](/docs/psw3.png)

This is the state of the system at the end of the Product Supply Workflow:

![Product Supply Workflow Final State](/docs/psw_fs.png)

## Product Purchase Workflow

### Workflow protagonists:
* **Customer**: Provides money to the store in exchange for product tokens.
* **Store**: Intermediates between the customer and the Emma contract, earning a profit.
* **Emma**: Interacts with the store contract by receiving payment and sending product tokens.

### Workflow

The following actions all take place in an atomic transaction:
* The customer sends money to the Store contract, requesting the purchase of some product.
* The store forwards the request to the Emma contract, keeping its cut of the money.
* The Emma contract sends the Product Tokens to the Store contract, keeping the funds.
* The Store contract sends the Product Tokens to the customer.

![Product Purchase Workflow 1](/docs/ppw1.png)

This is the state of the system at the end of the Product Purchase Workflow:

![Product Purchase Workflow Final State](/docs/ppw_fs.png)

## Profit Claiming Workflow

### Workflow protagonists:

* **Manufacturer**: Exchanges their Product Receipt Tokens for money, once the product has been sold to a customer.
* **Emma**: Sends the money to the manufacturer and burns the PRTs.

### Workflow:

1. When some or all of the product supplied by the manufacturer is sold, they will be able to exchange their Product Receipt Tokens for the corresponding profit.
2. The Emma contract discounts two fees from the manufacturer's payment:
    * The Emma contract fee
    * The warehouse fee

![Profit Claiming Workflow 1](/docs/pcw1.png)

This is the state of the system at the end of the Product Supply Workflow:

![Profit Claiming Workflow Final State](/docs/pcw_fs.png)


## Product Exchange Workflow

### Workflow protagonists:

* **Customer**: Exchanges their Product Tokens for the corresponding physical products.
* **Warehouse**: Delivers the physical product to the customer.
* **Emma**: Burns the Product Tokens and pays the warehouse for their service.

### Workflow:

1. Once the customer has purchased their products, they'll be able to exchange their Product Tokens for physical product.
2. The warehouse delivers the product to the customer once they have verified that the corresponding Product Tokens have been burned.

![Product Exchange Workflow 1](/docs/pew1.png)

3. Once the warehouse has delivered the product to the customer, they'll be able to claim the corresponding fee for their storage service.

![Product Exchange Workflow 2](/docs/pew2.png)

This is the state of the system at the end of the Product Supply Workflow:

![Product Exchange Workflow Final State](/docs/pew_fs.png)


## To Do

1. Batch addition of products to the inventory, by taking advantage of EIP-1155's batch operations.
2. Include the shipment service provider as one of the market participants. Currently it is assumed that payment for the shipping services is made off-chain by the sender of the goods, using traditional payment methods.
3. Make the protocol and warehouse fees adjustable via a function call.
4. Create a web-based graphical UX/UI for all the participants to interact with the system.

