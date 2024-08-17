import { ethers, upgrades } from 'hardhat';
const prompt = require('prompt-sync')();

const usdcAddresses = {
	bscTestnet: '0x64544969ed7EBf5f083679233325356EbE738930',
	bsc: '0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d',
	polygon: '0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359',
	base: '0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913',
	linea: '0x176211869cA2b568f2A7D4EE941E073a821EE1ff',
	ethereumMainnet: '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48',
};

const uniRouters = {
	bscTestnet: '0x1b81D678ffb9C0263b24A97847620C99d213eB14',
	bsc: '0xB971eF87ede563556b2ED4b1C0b0019111Dd85d2',
	polygon: '0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45',
	base: '0x2626664c2603336E57B271c5C0b26F421741e481',
	linea: '0x1b81D678ffb9C0263b24A97847620C99d213eB14',
	ethereumMainnet: '0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45',
};

const wrapperAddresses = {
	bscTestnet: '0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd',
	bsc: '0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c',
	polygon: '0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270',
	base: '0x4200000000000000000000000000000000000006',
	linea: '0xe5D7C2a44FfDDf6b295A15c148167daaAf5Cf34f',
	ethereumMainnet: '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2',
};

const chainLinkAddresses = {
	bscTestnet: ['0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526', 3600],
	bsc: ['0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE', 3600],
	polygonAmoy: ['0x001382149eBa3441043c1c66972b4772963f5D43', 120],
	polygon: ['0xAB594600376Ec9fD91F8e885dADF0CE036862dE0', 27],
	base: ['0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70', 1200],
	linea: ['0x3c6Cd9Cc7c7a4c2Cf5a82734CD249D7D593354dA', 86400],
	ethereumMainnet: ['0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419', 3600],
};

async function main() {
	console.log('[ 👾 ] Initializing...');
	console.log(
		`[ 👾 ] Deploying to chain: ${(await ethers.provider.getNetwork()).name}`
	);
	let usdcAddress;
	const network = (await ethers.provider.getNetwork()).name;

	if ((usdcAddresses as any)[network] != undefined)
		usdcAddress = (usdcAddresses as any)[network];
	else usdcAddress = prompt('[ 🧐 ] USDC address: ');
	console.log(`[ 👾 ] USDC address set to: ${usdcAddress}`);

	let routerAddress;
	if ((uniRouters as any)[network] != undefined)
		routerAddress = (uniRouters as any)[network];
	else routerAddress = prompt('[ 🧐 ] UniRouter address: ');
	console.log(`[ 👾 ] Router address set to: ${routerAddress}`);

	let nativeWrapper;
	if ((wrapperAddresses as any)[network] != undefined)
		nativeWrapper = (wrapperAddresses as any)[network];
	else nativeWrapper = prompt('[ 🧐 ] Native Token wrapper address: ');
	console.log(`[ 👾 ] Wrapper address set to: ${nativeWrapper}`);

	let heartBeat;
	let chainLinkAddress;
	if ((chainLinkAddresses as any)[network] != undefined) {
		chainLinkAddress = (chainLinkAddresses as any)[network][0];
		heartBeat = (chainLinkAddresses as any)[network][1];
	} else {
		chainLinkAddress = prompt('[ 🧐 ] Chain Link address: ');
		heartBeat = parseInt(prompt('[ 🧐 ] Heartbeat: '));
	}
	console.log(`[ 👾 ] Chain Link address set to: ${chainLinkAddress}`);

	const droplinkedWallet = '0x9CA686090b4c6892Bd76200e3fAA2EeC98f0528F';
	const droplinkedFee = 100;
	console.log('[ 👾 ] Droplinked fee is set to 100');

	console.log(`[ 👾 ] Starting deployment...`);

	const DropShopDeployer = await ethers.getContractFactory('DropShopDeployer');
	const deployer = await upgrades.deployProxy(
		DropShopDeployer,
		[heartBeat, droplinkedWallet, droplinkedFee],
		{ initializer: 'initialize' }
	);
	console.log('[ ✅ ] Deployer deployed to: ', await deployer.getAddress());
	const ProxyPayer = await ethers.getContractFactory('DroplinkedPaymentProxy');
	const proxyPayer = await ProxyPayer.deploy(heartBeat, chainLinkAddress);
	console.log('[ ✅ ] ProxyPayer deployed to: ', await proxyPayer.getAddress());
	// const FundsProxy = await ethers.getContractFactory("FundsProxy");
	// const fundsProxy = await FundsProxy.deploy(usdcAddress, routerAddress, nativeWrapper);
	// console.log('[ ✅ ] FundsProxy deployed to: ', await fundsProxy.getAddress());
}

main()
	.then(() => process.exit(0))
	.catch((error) => {
		console.error(error);
		process.exit(1);
	});
