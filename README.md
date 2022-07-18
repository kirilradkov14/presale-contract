# ICO Crowdfunding contract V1


## Intoduction
The recent years has shown a significant growth in funds raised by ICO (Initial Coin Offerings) as more and more projects are being launched on daily basis. The quick success of the fundraisings in the crypto space left the door open for countless scams and rugpulls. This smart contract presents a decentralized crowdfunding model, where the start up owner can offer tokens for sale to its earliest adopters and raise initial funds to kickstart the project. After the sale is concluded the contract adds trading liquidity to an AMM. If the ICO fails to reach its Soft Cap or the owner choses to cancel it, contributors can refund their ETH and the owner will have his tokens sent back to his wallet.


## How it works ?
#### The creator deploys the contract with the following args:
- _creatorWallet - ICO creator wallet
- _tokenInstance - Token address
- _tokenDecimals - Token decimals
- _uniswapv2Router - UniswapV2 Router
- _uniswapv2Factory - UniswapV2 Factory
- _fee - The fee that the ICO creator pays to the team in both tokens and ether
- _teamWallet - the team wallet
- _weth - Wrapped ethereum address
- _burnToken - when true burns the remaining tokens if the HardCap is not reached, when false refunds to the presale creator
#### The creator then initiates the sale, passing the following args:
- _saleRate - Tokens for 1 ETH on presale
- _listingRate - Tokens for 1 ETH on Uniswap
- _startTime - start of the sale
- _endTime - end of the sale
- _hardCap - the fundraising goal in ETH
- _softCap - the minimum raised amount of ETH required for the sale to be successful
- _maxBuy - maximum ETH amount a user can contribute to the sale
- _minBuy - minimum ETH amount a user can contribute to the sale
- _liquidityPortion - Liquidity percentage 
####  The creator deposits the tokens to the pool
#### After the tokens are deposited users can buy by sending ETH to the contract address
- if the sale requirements are passed, they will receive tokens based on their contribution
- if not the EVM will revert the transaction
#### If the HC is reached:
- The creator finishes the sale, provides liquidity to uniswap, pays fee to the team and withraws the raised funds
- The contributors can now claim their tokens
#### If the SC is reached and sale expires:
- The creator finishes the sale, provides liquidity to uniswap, pays fee to the team and withraws the raised funds
- The contributors can now claim their tokens
- The remaining tokens in the contract are either burnt or sent back to the creator depending on the option chosen
#### If the sale is canceled:
- The creator withraws the deposited tokens
- The contributors can now claim their ETH back
#### If the sale fails to reach SC: 
- The contributors can now claim their ETH back
- The creator can withraw the deposited tokens


## Features
#### Owner can:
- choose the sale rates and args
- call the finishSale function if either the HC is reached or SC is reached and sale time expired
- cancel the sale 
- withrawal back his tokens if the sale is unsuccessful

### User can:
- Contribute to the ICO and receive proportional amount of tokens
- Claim their tokens if the sale is successful
- Refund their investment if the sale is unsuccesful


## Functions
*** `constructor` *** - takes args and deploys contract

*** `initSale` *** - take args - _saleRate, _listingRate, _hardCap, _softCap, _minBuy, _maxBuy amount must be in wei

*** `fallback function` *** - allows users to contribute only when the sale is active and requirements are passed

*** `deposit` *** - calculates the amount and deposits them into contract

*** `cancelSale` *** - allows the creator to cancel the sale and start refund if the sale is still active

*** `buyTokens` *** - used to buy tokens based on the msg value if requirements are passed

*** `claimTokens` *** - used to claim the purchased tokens after the sale is completed

*** `refund` *** - used to refund the contributed ETH after the sale fails

*** `withrawTokens` *** - allows creator to withraw the deposited tokens to the contract once the sale fails

*** `finishSale` *** - allows the creator to finish the sale, provide liquidity, pay fees, withraw raised funds and burn/refund the remaining tokens if the hc is not reached

*** `_checkSaleRequirements` *** - checks if the requirements are met

## Tests
#### Included just few test in this repository that cover all ICO scenarios
1. Pass args, deposit tokens, reach HC, finish sale, claim
2. Pass args, deposit tokens, reach sc, wait sale to finish, finish sale, claim
3. Pass args, deposit tokens, cancel sale, start refund
4. Pass args, deposit tokens, fail to reach SC, wait to finish, refund