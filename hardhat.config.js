import "@nomicfoundation/hardhat-toolbox";
import { ethers } from "hardhat";

require("dotenv").config();

const Accounts = await ethers.getSigners();

module.exports = {
  solidity: {
    compilers: [
      {

        version: "0.8.20",
        settings: {
          enabled: true,
          runs: 1_000_000,
        },
        viaIR: true,

        version: "0.8.23",
        settings: {
          enabled: true,
          runs: 1_000_000,
        },
        viaIR: true,
      },

    ]

  },

  networks: {

    hardhat: {
      gas: "auto",       // Automatically estimate the gas
      blockGasLimit: 0x1fffffffffffff,
      allowUnlimitedContractSize: true
    },

    eth_mainnet:{
      url: process.env.ETH_MAINNET_HTTPS,
      accounts: Accounts
    },

    goerli: {
      url: process.env.ETH_GOERLI_HTTPS,
      accounts: Accounts
    },

    sepolia: {
      url: process.env.ETH_SEPOLIA_HTTPS,
      accounts: Accounts
    },

    bnb_testnet: {
      url: process.env.BNB_TESTNET_HTTPS,
      accounts: Accounts
    },

    bnb_mainnet: {
      url: process.env.BNB_MAINNET_HTTPS,
      accounts: Accounts
    },

    goerli_arb: {
      url: process.env.ARB_GOERLI_HTTPS,
      accounts: Accounts
    }
  },

  gasReporter: {
    enabled: true,
    currency: 'USD',
  },

  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
  
};