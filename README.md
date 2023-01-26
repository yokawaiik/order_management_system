# Order Management System

The enterprise distributed application project repository (without the client application part).

This project was developed for a master's thesis on the topic "Order management system for security systems for vehicles based on Blockchain technology".

The main results of the work are described here.



## Problems analysis 



## Design


  
### System's architecture



### Client-server interaction and client's architecture



### Technology stack

- Hardhat for developing and deployment smart contract, testing;
- Blockchain GoQuorum;
- Docker for blockchain;
- Solidity language for smart contracts;
- OpenZeppelin library for smart contracts.

## Developing (MVP)
### What was done

As a result of design and development, they have the following functional features:
- provide access control to the order management system and delimit access to the functions of a distributed application;
- provide full accounting of all available assets of organizations connected to the system;
- provides processes for the transfer of assets between organizations;
- provide processes for creating orders, save the history of movements;
- provide privileged users in the system with the ability to produce products, restore them and exit from service;
- the smart contract is designed in such a way as to ensure its scalability when deployed in a production environment.

### Way of improvements

To improve the smart contract:
- it is possible to redesign its architecture in such a way that each module is a separate distributed application;
- finalize the logic of product ownership for the consumer;
- improve the logic of product support;
- finalize the logic of buying goods and crediting to the consumer's balance.

## UI Design for desktop app

To design UI I used Penpot. File with the project available in  [folder](./docs/ui_design).

## Testing

Testing in the project was carried out partially and the main functions of the smart contract were tested. Not all tests were implemented.

## Conclusion

As a result of the work, a smart contract was implemented - the most significant, in the context of the study, part of the system. A smart contract has the following functional features:
- provide access control to the order management system and delimit access to the functions of a distributed application;
- provide full accounting of all available assets of organizations connected to the system;
- provides processes for the transfer of assets between organizations;
- provide processes for creating orders, save the history of movements;
- provide privileged users in the system with the possibilities of production, its restoration and decommissioning;
- the smart contract is designed in such a way as to ensure its scalability when deployed in a production environment.

Partial testing was carried out for the operation of the basic logic of the smart contract.