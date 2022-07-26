# ICO Crowdfunding contract V1

## Goal
This smart contract is a representation of a completely decentralized crowdfunding protocol, aiming to provide a safe and fair distribution of tokens and ETH during an ICO process. The idea behind is the implementation of a faster, easier, more efficient and more secure way for how to raise funds in order to kickstart your blockchain project.


## How it works ?
#### The fundraiser deploys the contract with the following args:
- _tokenInstance - the address of the token that's beeing sold
- _tokenDecimals - the decimals of the same token
- _uniswapv2Router - UniswapV2 Router
- _uniswapv2Factory - UniswapV2 Factory
- _burnToken - burn or refund the unsold tokens option
- _isWhitelist - Whitelist option
#### The fundraiser initiates the Pool options:
- _saleRate - Token amount for paying 1 ETH on ICO.
- _listingRate - Token amount for paying 1 ETH on Uniswap.
- _startTime - The starting time of the sale. (Timestamp).
- _endTime - The ending time of the sale. (Timestamp).
- _hardCap - The fundraising goal.
- _softCap - The minimum raised amount of ETH required for ICO to be successful.
- _maxBuy - Maximum amount that an eligible user can contribute to the ICO.
- _minBuy - Minimum amount that an eligible user can contribute to the ICO.
- _liquidityPortion - Percent of the funds raised in this sale that will be used as liquidity on Uniswap. (Must be at least 30).
####  The fundraiser deposits the tokens to the pool
#### After the tokens are deposited users can buy by sending ETH to the contract address
- If the sale requirements are passed, they will receive tokens based on their ETH contribution.
- If not the EVM will revert the transaction.
#### If the HC is reached:
- The fundraiser finishes the sale. By doing this the contract will automatically enable users to claim tokens, provide liquidity to Uniswap, pay the platform fees and withdrawal the funds.
#### If the SC is reached and sale expires:
- The fundraiser finishes the sale. By doing this the contract will automatically enable users to claim tokens, provide liquidity to Uniswap, pay the platform fees and withdrawal the funds.
- The remaining tokens will either be burnt or refunded to the fundraiser (Depending on the chosen option).
#### If the sale is canceled:
- The fundraiser withdrawals the deposited tokens to the contract. The user are now eligible to refund their ETH contribution.
#### If the sale fails to reach SC: 
- The fundraiser withdrawals the deposited tokens to the contract. The user are now eligible to refund their ETH contribution.


## Features
- Completely decentralized ICO Protocol.
- Whitelist functionality.
- Liquidity automatically added upon finalization.

 ## Technologies used:
 - Solidity
 - Hardhat
 - EthersJS
 - solhint

## Functions
 `constructor`  - deploys contract with the passed args

 `initSale`  - owner choses Pool option

 `fallback function`  - allows users to contribute only when the sale is active and requirements are passed

 `deposit`  - called by the owner to deposit the required token amount for the presale into the contract.

 `cancelSale`  - allows the owner to cancel the sale and start a refund process

 `buyTokens`  - used to buy tokens based on the msg value if requirements are passed

 `claimTokens`  - called by users for claiming the tokens

 `refund`  - called by users for refunding their contribution upon sale failure

 `withrawTokens`  - called by owner to withdraw the deposited tokens upon sale failure

 `finishSale`  - called by owner when the fundrasing requirements are met, once called - liquidity is provided, users can claim, fees are paid to the platform and owner can withdraw the raised ETH.

 `_checkSaleRequirements`  - on call, checks whether the requirements are met or not (presale is active, user is whitelisted, caps are met, sale is initialized and tokens are deposited)

## Tests
- The uploaded test includes every possible scenario, detailed tests on all functions one by one are not included.
