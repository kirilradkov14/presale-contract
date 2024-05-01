import { ethers, run } from "hardhat";


function sleep(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}

async function main() {
  const weth:string = "0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9"; //SEPOLIA
  const uniswapRouter:string = "0xC532a74256D3Db42D0Bf7a0400fEFDbad7694008";
  const token:string = "0x76E53d4b44d749fD59449c32643DEF979A378a5f";
  const timeNow:number = Math.floor(Date.now() / 1000);
  const pool = {
    tokenDeposit: ethers.parseUnits("10000000", 18), // 1B tokens
    hardCap: ethers.parseUnits("0.1", 18),
    softCap: ethers.parseUnits("0.05", 18),
    max: ethers.parseUnits("0.1", 18),
    min: ethers.parseUnits("0.01", 18),
    start: 1714474199,
    end: 1714475199,
    liquidityBps: 5000
};

  const Presale = await ethers.getContractFactory("Presale");
  const presale = await Presale.deploy(weth,token, uniswapRouter, pool);
  await presale.waitForDeployment();

  console.log(`Presale succesfully deployed: ${presale.target}`);
  
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});