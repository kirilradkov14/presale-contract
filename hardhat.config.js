require("@nomiclabs/hardhat-waffle");
require("dotenv").config();

task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
      console.log(account.address);
  }
});

module.exports = {
  solidity: "0.8.4",
  networks: {
    goerli: {
      chainId: 5,
      url: process.env.GOERLI_NODE,
      accounts: [process.env.PRIVATE_KEY_CREATOR, process.env.PRIVATE_KEY_USER_1, process.env.PRIVATE_KEY_USER_2, process.env.PRIVATE_KEY_USER_3],
    }
  },

  mocha: {
    timeout: 100000000
  }
};