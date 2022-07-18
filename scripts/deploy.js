// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  const Token = await hre.ethers.getContractFactory("Token");
  const token = await Token.deploy();
  await token.deployed();

  const Presale = await hre.ethers.getContractFactory("Presale");
  const presale = await Presale.deploy('0x3f78A4125fE0A26BA051903e07118b9e99AB3B49', token.address, 18, '0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D', '0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f', 2, '0xced1cB80C96D4b98DbcBbD20af69A5396Ec3507C', '0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6', false);
  await presale.deployed();
  const timestampNow = Math.floor(new Date().getTime()/1000);
  const initSale = await presale.initSale(BigInt(70000000000 * (10**18)), BigInt(90000000000*(10**18)), timestampNow + 35, timestampNow + 450, BigInt(3000000000000000), BigInt(2000000000000000), BigInt(3000000000000000), BigInt(3000000000000), 100);
  await initSale.wait();
  console.log("Presale contract at: ", presale.address);

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
