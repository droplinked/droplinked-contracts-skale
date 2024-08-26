import { HardhatUserConfig } from 'hardhat/config';
import '@nomicfoundation/hardhat-toolbox';
import '@openzeppelin/hardhat-upgrades';

import 'hardhat-interface-generator';

require('dotenv').config();

const config: HardhatUserConfig = {
	sourcify: {
		enabled: true,
	},
	networks: {
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
			calypsoHubTestnet: process.env.CALYPSO_API_KEY as string,
		},
		customChains: [
			{
				network: 'calypsoHubTestnet',
				chainId: 974399131,
				urls: {
					apiURL: 'https://internal.explorer.testnet.skalenodes.com:10011/api/', //v2
					browserURL: 'https://giant-half-dual-testnet.explorer.testnet.skalenodes.com/',
				},
			},
		],
	},
};

export default config;
