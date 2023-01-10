# Smart contracts - Order Management System

## Sample Hardhat Project


### Info about contract's modules

- [x] AccessControlManager
- only organizations have an inventory
- [x] ProductsManager 
- transfer only organization to organization
- no transfer product from organization to user
- [x] OrdersManager
- create order, block products when order is confirmed, finish order and transferring products


### Test contract
```
    npx hardhat test
```

### Deploy contract

Deploy contract script to local blockchain  
```
    npx hardhat run scripts/deploy.ts --network goquorum
```

Deploy contract to local hardhat
```
    npx hardhat run scripts/deploy.ts
```


## Testing


### Info about contract testing

- [x] Test Suits 1: administrators logics (only primary)
  Testing the logic of administrator capabilities: assigning access rights to users, creating new privileged users, assigning administrators and not being able to change the access rights of other users with equal or higher rights

- [x] Test Suits 2: simple users access control (only primary) 
    Testing the logic of the user's ability to manage access rights: a regular user cannot assign roles and block other users, checking the possibility of blocking their own account

- [x] Test Suits 3: testing the logic of interaction with organizations (only primary) 
    Testing the logic of interaction with organizations in management:
    creation of an organization only for authorized users (by the system administrator), adding a new employee to the organization, changing the role of an organization member, deleting an employee, an attempt to change the role of an employee by an administrator of another organization, an attempt by a regular employee to change his own and someone else's role, or to delete another employee

- [x] Test Suits 4: product controlling (only primary) 
    Verify manufacturer registration, manufacture product by manufacturer, attempt other roles to produce, manufacturer employees cannot change production, update product status by organization employee, transfer products between organizations, other users attempt to transfer organization assets, attempt to update product status when not in own inventory organization, manufacturer unlocked product verification, manufacturer product unrepairable (if warranty expired), non-manufacturer unable to repair product, manufacturer ownership unlock verification, selling product to customer

- [x] Test Suits 5: orders interactions (only primary) 
    Check for creating a new order, adding a product (in vendor inventory) to an unconfirmed order, deleting products from an unconfirmed order, confirming an order, not being able to confirm an order by an outside supplier or customer and completing it, not being able to add products to a confirmed order, not being able to delete a confirmed order, updating status order (available only to the supplier), inability to update the status of the order by the supplier, check the refusal of the proposed order, delete only unconfirmed order, the inability to delete the confirmed order, check the completion of the order, check the completion of the order if only one of the participants confirmed it, the impossibility of transportation while the order is incomplete, confirmation of transfer of products from a completed order, the impossibility of re-transfer of products from a completed order, verification of an attempt to delete an order by an outside user, an attempt to cancel an order when both parties confirm it or

### Test Suits

#### Run tests into a local blockchain

1. Run a local blockchain
``` 
    npx hardhat node
``` 

2. Run tests
```
    npx hardhat test --network localhost                                                            
```

#### Run tests with comands

- To test all test suits
```
    npx hardhat test --grep 'TS'
```

- To test all test suits
```
    npm run test-suits
```


