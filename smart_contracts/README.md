# Sample Hardhat Project



## Info about contract's modules

- [x] AccessControlManager
- only organizations have an inventory
- [x] ProductsManager 
- transfer only organization to organization
- no transfer product from organization to user
- [x] OrdersManager
- create order, block products when order is confirmed, finish order and transferring products


## Test contract
```
    npx hardhat test
```

## Deploy contract

Deploy contract script to local blockchain  
```
    npx hardhat run scripts/deploy.ts --network goquorum
```

Deploy contract to local hardhat
```
    npx hardhat run scripts/deploy.ts
```



