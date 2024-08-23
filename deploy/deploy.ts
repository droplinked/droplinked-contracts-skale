import { ethers, upgrades } from 'hardhat';

async function main() {
	console.log('[ 👾 ] Initializing...');
	console.log(
		`[ 👾 ] Deploying to chain: ${(await ethers.provider.getNetwork()).name}`
	);
	const droplinkedWallet = '0x9CA686090b4c6892Bd76200e3fAA2EeC98f0528F';
	const droplinkedFee = 100;
	console.log('[ 👾 ] Droplinked fee is set to 100');

	console.log(`[ 👾 ] Starting deployment...`);

	const DropShopDeployer = await ethers.getContractFactory('DropShopDeployer');
	const deployer = await upgrades.deployProxy(
		DropShopDeployer,
		[droplinkedWallet, droplinkedFee],
		{ initializer: 'initialize' }
	);
	console.log('[ ✅ ] Deployer deployed to: ', await deployer.getAddress());
	const ProxyPayer = await ethers.getContractFactory('DroplinkedPaymentProxy');
	const proxyPayer = await ProxyPayer.deploy();
	console.log('[ ✅ ] ProxyPayer deployed to: ', await proxyPayer.getAddress());
}

main()
	.then(() => process.exit(0))
	.catch((error) => {
		console.error(error);
		process.exit(1);
	});
