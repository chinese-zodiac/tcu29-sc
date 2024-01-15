## TCu29 Sale

Allows purchase of TCu29 up to $10,000 in one transaction, with no slippage.

## Official Deployments

BSC:0xC324C1f146713b2d6ae6EcCa2DD4288c84D8018b

## deployment

The admin address is hardcoded in the deployment script.

forge script script/DeployTCu29Sale.s.sol:DeployTCu29Sale --broadcast --verify -vvv --rpc-url https://rpc.ankr.com/bsc --etherscan-api-key $ETHERSCAN_API_KEY -i 1 --sender $DEPLOYER_ADDRESS
