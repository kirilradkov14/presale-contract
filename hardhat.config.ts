import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

require('dotenv').config();

const Accounts = [
  process.env.PK_ACCOUNT1,
  process.env.PK_ACCOUNT2,
  process.env.PK_ACCOUNT3,
  process.env.PK_ACCOUNT4,
  process.env.PK_ACCOUNT5,
  process.env.PK_ACCOUNT6
].filter(account => account !== undefined) as string[];

const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: "0.8.20",
        settings: {
          optimizer: {
            enabled: true,
            runs: 1_000_000,
          },
          viaIR: true,
        },
      },
      {
        version: "0.8.24",
        settings: {
          optimizer: {
            enabled: true,
            runs: 1_000_000,
          },
          viaIR: true,
        },
      },
    ],
  },
  networks: {
    hardhat: {
      gas: "auto",       // Automatically estimate the gas
      blockGasLimit: 0x1fffffffffffff,
      allowUnlimitedContractSize: true,
      accounts: {
        count: 400
    }
    },
    eth_mainnet:{
      url: process.env.ETH_MAINNET_HTTPS as string,
      accounts: Accounts
    },
    goerli: {
      url: process.env.ETH_GOERLI_HTTPS as string,
      accounts: Accounts
    },
    sepolia: {
      url: process.env.ETH_SEPOLIA_HTTPS as string,
      accounts: Accounts,
      timeout: 150_000
    },
    bnb_testnet: {
      url: process.env.BNB_TESTNET_HTTPS as string,
      accounts: Accounts
    },
    bnb_mainnet: {
      url: process.env.BNB_MAINNET_HTTPS as string,
      accounts: Accounts
    },
    goerli_arb: {
      url: process.env.ARB_GOERLI_HTTPS as string,
      accounts: Accounts
    }
  },
  mocha: {
    timeout: 1_000_000
  },
  gasReporter: {
    enabled: true,
    currency: 'USD',
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY as string,
  },
};

export default config;