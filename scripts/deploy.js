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

  const presaleFactory = await hre.ethers.getContractFactory("Presale");
  const presale = await presaleFactory.deploy(token.address, 18, 'Router', 'Factory', 'enter your marketing address here', 'enter the WBNB address here', true, false);
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
