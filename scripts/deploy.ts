import { ethers } from "hardhat";

async function main() {
  const _WETH = "0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9"; //SEPOLIA
  const _UNISWAP_ROUTER = "0";
  const _UNISWAP_FACTORY = "0";
  const _TOKEN = "";
  const _REFUND = 0;
  
  const Pool = {
     saleRate: 10,
     listingRate: 5,
     hardCap: 1,
     softCap: 1,
     max: 1,
     min: 0.1,
     start: 1,
     end: 1,
     liquidity: 1,
  }

  const Presale = await ethers.getContractFactory("Presale");
  const presale = await Presale.deploy(_WETH, _UNISWAP_ROUTER, _UNISWAP_FACTORY);
  await presale.waitForDeployment();
  
//   const LimitOrderFactory = await ethers.getContractFactory("LimitOrderProtocol");
//   const LimitOrderProtocol = await LimitOrderFactory.deploy(ethers.getAddress(_WETH_SEPOLIA));
//   await LimitOrderProtocol.waitForDeployment();
//   console.log("Limit Order Protocol deployed at: " + LimitOrderProtocol.target);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});