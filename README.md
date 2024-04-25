## TCu29 Sale

Allows purchase of TCu29 up to $10,000 in one transaction, with no slippage.

## Official Deployments

TCu29
BSC:0x5b0B5c848a843c83c20dcfa25CDe6E122898a614

TCu29Sale
BSC:0xC324C1f146713b2d6ae6EcCa2DD4288c84D8018b

Tcu29PoolMaster
BSC:0x44d32cB563175294F9869a37Fe7fA3861a62022B

## deployment

The admin address is hardcoded in the deployment script.

forge script script/DeployTCu29Sale.s.sol:DeployTCu29Sale --broadcast --verify -vvv --rpc-url https://rpc.ankr.com/bsc --etherscan-api-key $ETHERSCAN_API_KEY -i 1 --sender $DEPLOYER_ADDRESS
