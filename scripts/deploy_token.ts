import { ethers, run } from "hardhat";

function sleep(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
}

async function main() {
    const name:string = "TestToken";
    const symbol:string = "TEST";
    const totalSupply:bigint = 1_000_000_000n * 10n ** 18n;

    const Token = await ethers.getContractFactory("Token");
    const token = await Token.deploy(totalSupply, name, symbol);
    await token.waitForDeployment();

    console.log(`Token succesfully deployed: ${token.target}`);

}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });