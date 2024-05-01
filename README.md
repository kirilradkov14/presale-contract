# 🚀  Presale Smart Contract

This contract is built to provide a comprehensive solution for managing token presales, ensuring transparency and security for both project owners and contributors.

The contract starts with the deployment phase where the token parameters, such as hard cap, soft cap, minimum and maximum contributions, and liquidity allocation, are defined. Once deployed and tokens are deposited by the owner, the presale phase begins, allowing participants to contribute within the defined timeframe. At the end of the presale, if the soft cap is met, the contract transitions into the finalization phase, automatically allocating a portion of the funds to liquidity on UniswapV2 and enabling token claims for contributors. Should the presale not meet its minimum goals or be cancelled, it supports a refund mechanism, ensuring that participants can retrieve their contributions under these conditions.

## 👉 Features

- **Token Management:** Handle deposits, and manage tokens throughout the presale lifecycle.
- **Token Claim:** Participants can claim their tokens after the presale concludes successfully.
- **Cancel:** Allows the owner to cancel the presale, enabling refunds under certain conditions.
- **Refunds:** Offers a refund mechanism for participants if the presale does not reach its soft cap or is cancelled.
- **Hard Cap and Soft Cap:** Define minimum and maximum funding goals to steer the presale's success criteria.
- **Timed Rounds:** Presale starts and ends are strictly timed – no contributions outside this window.
- **Automatic Liquidity Allocation:** A predefined portion of the funds raised is automatically converted into liquidity and added to UniswapV2.

## ✔️ How to Deploy

To get this contract up and running, you’ll need [Node.js](https://nodejs.org/) installed on your machine, along with [Hardhat](https://hardhat.org/getting-started/) set up in a TypeScript environment. Here’s how you can deploy it step by step:

1. **Clone the repo:**
   ```bash
   git clone https://github.com/kirilradkov14/presale-contract.git
   cd <your-project-folder>
   ```

2. **Install dependencies:**
    ```bash
    npm install
    ```

3. **Set up your environment variables:**
    Create a `.env` file in the root of your project and populate it with necessary configurations like wallet private keys and Provider API keys as seen on example below:
    ```plaintext
    ETH_SEPOLIA_HTTPS =your-sepolia-https-rpc-here

    PK_ACCOUNT1 =your-wallet-private-key-here
    PK_ACCOUNT2 =your-wallet-private-key-here
    PK_ACCOUNT3 =your-wallet-private-key-here
    PK_ACCOUNT4 =your-wallet-private-key-here
    PK_ACCOUNT5 =your-wallet-private-key-here
    PK_ACCOUNT6 =your-wallet-private-key-here
    ```

4.  **Compile the contracts:**
    ```bash
    npx hardhat compile
    ```

5. **Deploy to the network:**
    Adjust the `hardhat.config.ts` file to include the desired network settings.
    ```bash
    import * as dotenv from 'dotenv';
    dotenv.config();

    module.exports = {
    solidity: "0.8.24",
    networks: {
        sepolia: {
            url: process.env.ETH_SEPOLIA_HTTPS as string,
            accounts: Accounts,
            timeout: 150_000
        }
    }
    };
    ```

    Then run:
    ```bash
    npx hardhat run scripts/deploy_presale.ts --network sepolia
    ```

6. **Verify and interact with your contract on Etherscan**

## ❗Important consideration

### Testing and Audits
It's essential to thoroughly test this contract on testnets before even thinking about hitting production. It hasn't been audited by external parties. So, if you're planning to use this for serious stuff, consider getting a professional audit to check everything’s in order.

### Use at Your Own Risk
This contract comes as is, without any guarantees that it's free of bugs or vulnerabilities. If you decide to use it, you're doing so at your own risk. Make sure you fully understand what the contract does before deploying it.

### Liquidity Considerations
The contract automatically adds liquidity to Uniswap after a presale, but be aware, this liquidity isn't locked. That means it can be withdrawn, potentially impacting the token's stability. If you need the liquidity locked, this setup might require some tweaks.

## ✨ Conclusion

Thank you for exploring the Presale Smart Contract! 

The Presale Smart Contract is freely available under the MIT License. This means you are free to use, modify, and distribute the project as you see fit.

Happy deploying! 🚀
