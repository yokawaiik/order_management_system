# Sample Hardhat Project





Product Manager:
produceNewProduct()
restoreProduct()
removeProduct()
getProductById()
getAllProductsByOwner()
setNewOwnerToProduct()

	Users Manager (Access Control):
getUserInventory()
transferItemToUser()
createUser()
getUserById()
revokeUser()
setRole()

		Order Manager:
			getOrderById()
			getOrderByRequestUserId()	
getOrderBySupplyerUserId()
			getOrderByProductId()
			createOrder()
updateOrderById()
			addProductToOrderById()
			removeProductFromOrderById()
			setStateProductTransferById()
			updateOrderStatusById()

		Support (Service) Manager:
			getSupportOrderById()
			getSupportOrderByRequestUserId()
			getSupportOrderByProductId()
			createSupportOrder()
			setStateSupportProductTransfer()
			updateSupportOrderStatus()





```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat run scripts/deploy.ts
```
