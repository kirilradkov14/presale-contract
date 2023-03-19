
# Presale Smart Contract


Introducing a powerful and versatile smart contract for conducting a presale of an ERC20 token, inspired by the functionality of PinkSale and dxSale platforms. This decentralized crowdfunding protocol aims to provide a safe, fair, and efficient distribution of tokens and ETH during the ICO process. The contract allows the token's creator to set up a presale with customizable parameters such as start and end time, hard cap, soft cap, and more. Users can participate in the presale by sending Ether to the contract and claim their purchased tokens once the presale is over. If the soft cap is not met, participants have the option to request a refund. This innovative solution simplifies the fundraising process for blockchain projects, ensuring a faster, easier, and more secure way to kickstart your project.


## Table of contents
- Features
- Installation
- Configuration
- Usage
- Events
- Functions

## Features

- Customizable presale parameters
- Whitelisting functionality
- Automatic pair creation and liquification on Uniswap V2
- Option to burn or refund unsold tokens
- Supports cancellation and refunds


## Installation
Open a terminal or command prompt on your local machine.
Change the current directory to the location where you want to clone the repository. 
For example:
<pre>
cd /path/to/your/directory
</pre>
Run the following command to clone the repository:
<pre>
git clone https://github.com/kirilradkov14/presale-contract.git
</pre>
The repository will be cloned into a new folder named presale-contract within your chosen directory. To access the repository, run:
<pre>
cd presale-contract
</pre>
This contract uses the Hardhat framework with JavaScript. To get started, first install the necessary dependencies:
<pre>
npm install
</pre>
<p>Next, compile the contract:</p>
<pre>
npx hardhat compile
</pre>

## Configuration

Before deploying the contract, you need to configure the following parameters in the constructor:

- **_tokenInstance**: The ERC20 token instance.
- **_tokenDecimals**: The number of decimals for the token.
- **_uniswapv2Router**: The address of the Uniswap V2 router.
- **_uniswapv2Factory**: The address of the Uniswap V2 factory.
- **_weth**: The address of the Wrapped Ether (WETH) token.
- **_burnTokens**:  A boolean flag to enable or disable the burn feature.
- **_isWhitelist**: A boolean flag to enable or disable the whitelist feature.


Once the constructor parameters have been set, you can deploy the contract using the Hardhat framework:

<pre>
npx hardhat run scripts/deploy.js --network <network_name>
</pre>

Replace **<network_name>** with the desired network (e.g., **mainnet**, **ropsten**, **rinkeby**, **kovan**, or **localhost**)

## Usage
1. Call the **initSale()** function to set up the presale parameters.<br>
2. Call the **deposit()** function to deposit the tokens to be sold during the presale.<br>
3. Participants can send Ether to the contract during the presale period to purchase tokens.<br>
4. After the presale is over, call the **finishSale()** function to finalize the sale and create a Uniswap V2 liquidity pool.<br>
5. Participants can then call the **claimTokens()** function to claim their purchased tokens.<br>
6. If the soft cap is not met, participants can call the **refund()** function to request a refund.<br>

## Events
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

