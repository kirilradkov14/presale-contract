
# Presale Smart Contract

<p>
Introducing a powerful and versatile smart contract for conducting a presale of an ERC20 token, inspired by the functionality of PinkSale and dxSale platforms. This decentralized crowdfunding protocol aims to provide a safe, fair, and efficient distribution of tokens and ETH during the ICO process. The contract allows the token's creator to set up a presale with customizable parameters such as start and end time, hard cap, soft cap, and more. Users can participate in the presale by sending Ether to the contract and claim their purchased tokens once the presale is over. If the soft cap is not met, participants have the option to request a refund. This innovative solution simplifies the fundraising process for blockchain projects, ensuring a faster, easier, and more secure way to kickstart your project.
</p>

## Table of contents
- Features
- Installation
- Configuration
- Usage
- Events
- Functions
<br>
##Features

- Customizable presale parameters
- Whitelisting functionality
- Automatic liquidity pool creation on Uniswap V2
- Option to burn or refund unsold tokens<
- Supports cancellation and refunds


##Installation
<p>This contract uses the Hardhat framework with JavaScript. To get started, first install the necessary dependencies:</p>
<pre>
npm install
</pre>
<p>Next, compile the contract:</p>
<pre>
npx hardhat compile
</pre>
## Configuration
<p>Before deploying the contract, you need to configure the following parameters in the constructor:</p>
- **_tokenInstance**: The ERC20 token instance.
- **_tokenDecimals**: The number of decimals for the token.
- **_uniswapv2Router**: The address of the Uniswap V2 router.
- **_uniswapv2Factory**: The address of the Uniswap V2 factory.
- **_weth**: The address of the team's wallet.
- **_burnTokens**: The address of the Wrapped Ether (WETH) token.
- **_isWhitelist"**: A boolean flag to enable or disable the whitelist feature.

Once the constructor parameters have been set, you can deploy the contract using the Hardhat framework:

<pre>
```bash
npx hardhat run scripts/deploy.js --network <network_name>
```
</pre>
<p>Replace **<network_name>** with the desired network (e.g., **mainnet**, **ropsten**, **rinkeby**, **kovan**, or **localhost**).</p>

##Usage
1. Call the **initSale()** function to set up the presale parameters.<br>
2. Call the **deposit()** function to deposit the tokens to be sold during the presale.<br>
3. Participants can send Ether to the contract during the presale period to purchase tokens.<br>
4. After the presale is over, call the **finishSale()** function to finalize the sale and create a Uniswap V2 liquidity pool.<br>
5. Participants can then call the **claimTokens()** function to claim their purchased tokens.<br>
6. If the soft cap is not met, participants can call the **refund()** function to request a refund.<br>

##Events
- **Liquified**
- **Canceled**
- **Bought**
- **Refunded**
- **Deposited**
- **Claimed**
- **RefundedRemainder**
- **BurntRemainder**
- **Withdraw**

## Functions
- **initSale()**: Initializes the presale parameters.
- **deposit()**: Deposits tokens into the presale contract.

