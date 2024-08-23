import { HardhatUserConfig } from 'hardhat/config';
import '@nomicfoundation/hardhat-toolbox';
import '@openzeppelin/hardhat-upgrades';

import 'hardhat-interface-generator';

require('dotenv').config();

const config: HardhatUserConfig = {
	networks: {
		ethereumMainnet: {
			url: 'https://mainnet.infura.io/v3/55bd630c4e164c04bb27fff3f59babb0',
			chainId: 1,
			accounts: [process.env.PRIVATE_KEY as string],
		},
		bscTestnet: {
			url: 'https://data-seed-prebsc-1-s1.binance.org:8545',
			chainId: 97,
			gasPrice: 20000000000,
			accounts: [process.env.PRIVATE_KEY as string],
		},
		bsc: {
			url: 'https://bsc-dataseed.binance.org/',
			chainId: 56,
			accounts: [process.env.PRIVATE_KEY as string],
		},
		polygonAmoy: {
			url: 'https://rpc-amoy.polygon.technology',
			chainId: 80002,
			accounts: [process.env.PRIVATE_KEY as string],
		},
		polygon: {
			url: 'https://polygon-rpc.com/',
			chainId: 137,
			accounts: [process.env.PRIVATE_KEY as string],
		},
		linea: {
			url: 'https://1rpc.io/linea',
			chainId: 59144,
			accounts: [process.env.PRIVATE_KEY as string],
		},
		base: {
			url: 'https://mainnet.base.org/',
			chainId: 8453,
			accounts: [process.env.PRIVATE_KEY as string],
		},
		sepolia: {
			url: 'https://sepolia.infura.io/v3/',
			chainId: 11155111,
			accounts: [process.env.PRIVATE_KEY as string],
		},
		calypsoHubTestnet: {
			url: 'https://testnet.skalenodes.com/v1/giant-half-dual-testnet',
			chainId: 974_399_131,
			accounts: [process.env.PRIVATE_KEY as string],
		},
	},
	solidity: {
		version: '0.8.20',
		settings: {
			viaIR: true,
			optimizer: {
				enabled: true,
				runs: 200,
			},
		},
	},
	etherscan: {
		apiKey: {
			bscTestnet: process.env.BINANCE_API_KEY as string,
			bsc: process.env.BINANCE_API_KEY as string,
			polygonAmoy: process.env.POLYGON_API_KEY as string,
			polygon: process.env.POLYGON_API_KEY as string,
			base: process.env.BASE_API_KEY as string,
			linea: process.env.LINEA_API_KEY as string,
			ethereumMainnet: process.env.ETH_API_KEY as string,
		},
		customChains: [
			{
				network: 'polygonAmoy',
				chainId: 80002,
				urls: {
					apiURL: 'https://www.oklink.com/api/explorer/v1/contract/verify/async/api/polygonAmoy',
					browserURL: 'https://www.oklink.com/polygonAmoy',
				},
			},
			{
				network: 'linea',
				chainId: 59144,
				urls: {
					apiURL: 'https://api.lineascan.build/api',
					browserURL: 'https://goerli.lineascan.build/',
				},
			},
		],
	},
};

export default config;
