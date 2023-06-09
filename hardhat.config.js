require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

const getAccounts = [
  process.env.PK_ACCOUNT1,
  process.env.PK_ACCOUNT2,
  process.env.PK_ACCOUNT3,
  process.env.PK_ACCOUNT4,
  process.env.PK_ACCOUNT5,
  process.env.PK_ACCOUNT6
]

module.exports = {
  solidity: "0.8.19",
  networks: {
    goerli: {
      url: process.env.ALCHEMY_GOERLI_HTTP,
      accounts: getAccounts
    },
    sepolia: {
      url: process.env.ALCHEMY_SEPOLIA_HTTP,
      accounts: getAccounts
    },
    bsct: {
      url:process.env.BINANCE_TESTNET,
      accounts: getAccounts
    },
    bscm: {
      url:process.env.BINANCE_MAINNET,
      accounts: getAccounts
    }
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
}