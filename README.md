# Droplinked Solidity Contracts
This repository contains the droplinked's smart-contract source code for EVM chains that droplinked integrates with, including Skale, Polygon, Binance & Hedera 

## Setup

Use the .env.example file to build your own .env file before compiling/deploying onchain

## Deploy
To deploy the droplinked contracts to a network, follow these steps:

* Add your network to the `hardhat.config.ts` file, by simply looking at the exapmles that are there

* Put your etherscan/blockscout `api key` in the etherscan part

* Run the following command to deploy :

  `npx hardhat run scripts/deploy.ts --network $network_name_here$`

For instance, running

```
npx hardhat run scripts/deploy.ts --network calypsoHubTestnet
```

would result in something like this

```
[ ✅ ] Deployer deployed to: 0x34C4db97cE4cA2cce48757F85C954C5647124106
[ ✅ ] PaymentProxy deployed to: 0x34C4db97cE4cA2cce48757F85C954C5647124106
```
