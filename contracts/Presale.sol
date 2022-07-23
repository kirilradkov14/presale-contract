pragma solidity ^0.8.4;
// SPDX-License-Identifier: Unlicensed
// A+G = VNL
// https://github.com/kirilradkov14

import './IUniswap.sol';
import './IERC20.sol';
import './Ownable.sol';
import './Whitelist.sol';

/*
* !=======================================! Presale contract !=======================================!
*/
contract Presale is Ownable, Whitelist {

    bool isInit;
    bool isDeposit;
    bool isRefund;
    bool isFinish;
    bool burnTokens;
    bool isWhitelist;
    address creatorWallet;
    address constant teamWallet = 0xced1cB80C96D4b98DbcBbD20af69A5396Ec3507C;
    address constant weth = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;
    uint8 constant fee = 2;
    uint8 tokenDecimals;
    uint256 presaleTokens;
    uint256 ethRaised;

    IERC20 public tokenInstance;
    IUniswapV2Factory UniswapV2Factory;
    IUniswapV2Router02 UniswapV2Router02;

    struct Pool {
        uint256 liquidityPortion;
        uint256 softCap;
        uint256 hardCap;
        uint256 minBuy;
        uint256 maxBuy;
        uint256 saleRate;
        uint256 listingRate;
        uint256 startTime;
        uint256 endTime;    
    }


    Pool public pool;

    mapping(address => uint256) public ethContribution;


    /*
    * !=======================================! Modifiers !=======================================!
    */
    // presale is running
    modifier onlyActive {
        require(block.timestamp >= pool.startTime);
        require(block.timestamp <= pool.endTime, 'Presale must be active.');
        _;
    }
    //presale not started yet, has finished or hardCap reached
    modifier onlyInactive {
        require(block.timestamp < pool.startTime || block.timestamp > pool.endTime || ethRaised >= pool.hardCap, 'Presale must be inactive.');
        _;
    }
    modifier onlyRefund {
        require(isRefund == true || (block.timestamp > pool.endTime && ethRaised <= pool.hardCap), 'Refund unavailable');
        _;
    }

    /*
    *  !=======================================! Events !=======================================!
    */
    event Liquified(
        address indexed _token, 
        address indexed _router, 
        address indexed _pair
        );

    event Canceled(
        address indexed _inititator, 
        address indexed _token, 
        address indexed _presale
        );

    event Bought(address indexed _buyer, uint256 _tokenAmount);

    event Refunded(address indexed _refunder, uint256 _tokenAmount);

    event Deposited(address indexed _initiator, uint256 _totalDeposit);

    event Claimed(address indexed _participent, uint256 _tokenAmount);

    event RefundedRemainder(address indexed _initiator, uint256 _amount);

    event BurntRemainder(address indexed _initiator, uint256 _amount);

    event Withdraw(address indexed _creator, uint256 _amount);
    

    constructor(
        IERC20 _tokenInstance, 
        uint8 _tokenDecimals, 
        address _uniswapv2Router, 
        address _uniswapv2Factory, 
        bool _burnTokens,
        bool _isWhitelist
        ) {

        require(address(_tokenInstance) != address(0), 'creatorWallet can not be 0 address.');
        require(_uniswapv2Router != address(0), 'Router must be different from 0 address');
        require(_uniswapv2Factory != address(0), 'Factory must be different from 0 address');
        require(_tokenDecimals >= 0, 'Invalid value for decimals');
        require(_tokenDecimals <= 18, 'Invalid value for decimals');

        isInit = false;
        isDeposit = false;
        isFinish = false;
        isRefund = false;
        ethRaised = 0;

        burnTokens = _burnTokens;
        isWhitelist = _isWhitelist;
        tokenInstance = _tokenInstance;
        creatorWallet = address(payable(msg.sender));
        tokenDecimals =  _tokenDecimals;
        UniswapV2Router02 = IUniswapV2Router02(_uniswapv2Router);
        UniswapV2Factory = IUniswapV2Factory(_uniswapv2Factory);

        tokenInstance.approve(_uniswapv2Router, tokenInstance.totalSupply());
        require(UniswapV2Factory.getPair(address(tokenInstance), weth) == address(0), "Error: Uniswap pool already existing.");
    }

    /*
    * Fallback function reverts ethers sent to this address whenever requirements are not met
    */
    receive() external payable {
        if(block.timestamp >= pool.startTime && block.timestamp <= pool.endTime){
            buyTokens(_msgSender());
        } else {
            revert('Pre-Sale is closed');
        }
    }

    /*
    * Initiates the arguments of the sale
    @dev arguments must be passed in wei (amount*10**18)
    */
    function initSale(
        uint256 _saleRate, 
        uint256 _listingRate, 
        uint256 _startTime, 
        uint256 _endTime, 
        uint256 _hardCap, 
        uint256 _softCap, 
        uint256 _maxBuy, 
        uint256 _minBuy, 
        uint8 _liquidityPortion
        )external onlyOwner onlyInactive {        

        require(isInit == false, 'Sale is already initialized');
        require(_startTime >= block.timestamp, 'Start time must exceed current timestamp.');
        require(_endTime > block.timestamp, 'End time must exceed current timestamp');
        require(_softCap >= _hardCap / 2, 'Soft cap must be at least 50% of hardcap.');
        require(_liquidityPortion >= 30, 'At least 30% ethers should go to liquidity .');
        require(_liquidityPortion <= 100);
        require(_minBuy < _maxBuy, 'Invalid value for minBuy.');
        require(_minBuy > 0);
        require(_saleRate > 0, 'token - ether ratio must be more than 0.');
        require(_listingRate > 0, 'token - ether ratio must be more than 0.');

        pool.saleRate = _saleRate;
        pool.listingRate = _listingRate;
        pool.startTime = _startTime;
        pool.endTime = _endTime;
        pool.hardCap = _hardCap;
        pool.softCap = _softCap;
        pool.liquidityPortion = _liquidityPortion;
        pool.minBuy = _minBuy;
        pool.maxBuy = _maxBuy;

        isInit = true;
    }

    /*
    * Once called the owner deposits tokens into pool
    */
    function deposit() external onlyOwner {
        require(isDeposit == false, 'Tokens already deposited to the pool.');
        require(isInit == true, 'Pool not initialized yet');

        uint256 tokensForSale = pool.hardCap * (pool.saleRate) / (10**18) / (10**(18-tokenDecimals));
        presaleTokens = tokensForSale;
        uint256 totalDeposit = _getTokenDeposit();

        tokenInstance.transferFrom(msg.sender, address(this), totalDeposit);
        emit Deposited(msg.sender, totalDeposit);

        //updating the boolean prevents from using the function again ever
        isDeposit = true;
    }

    /*
    * The owner can decide to close the sale if it is still active
    NOTE: Creator may call this function even if the Hard Cap is reached, to prevent it use:
     require(ethRaised < pool.hardCap)
    */
    function cancelSale() external onlyOwner onlyActive {
        require(isFinish == false, 'This sale has already finished.');
        pool.endTime = 0;
        isRefund = true;

        if (tokenInstance.balanceOf(address(this)) > 0) {
            uint256 tokenDeposit = _getTokenDeposit();
            tokenInstance.transfer(msg.sender, tokenDeposit);
            emit Withdraw(msg.sender, tokenDeposit);
        }
        emit Canceled(msg.sender, address(tokenInstance), address(this));
    }

    /*
    * Allows participents to claim the tokens they purchased 
    */
    function claimTokens() external onlyInactive {
        require(isFinish == true, 'Sale is still active');
        require(!isRefund, 'Cannot claim during refund.');

        uint256 tokensAmount = _getUserTokens(ethContribution[msg.sender]);
        ethContribution[msg.sender] = 0;
        tokenInstance.transfer(msg.sender, tokensAmount);
        emit Claimed(msg.sender, tokensAmount);
    }

    /*
    * Refunds the Eth to participents
    */
    function refund() external onlyInactive onlyRefund{
        uint256 refundAmount = ethContribution[msg.sender];
        
        if (address(this).balance >= refundAmount) {
            if (refundAmount > 0) {
                address payable refunder = payable(msg.sender);
                refunder.transfer(refundAmount);
                emit Refunded(refunder, refundAmount);
            }
        }
    }

    /*
    * Withdrawal tokens on refund
    */
    function withrawTokens() external onlyOwner onlyInactive onlyRefund {
        if (tokenInstance.balanceOf(address(this)) > 0) {
            uint256 tokenDeposit = _getTokenDeposit();
            tokenInstance.transfer(msg.sender, tokenDeposit);
            emit Withdraw(msg.sender, tokenDeposit);
        }
    }

    /*
    * Finish the sale - Create Uniswap v2 pair, add liquidity, take fees, withrdawal funds, burn unused tokens
    */
    function finishSale() external onlyOwner onlyInactive{
        require(ethRaised >= pool.softCap, 'Soft Cap is not met');
        require(block.timestamp > pool.startTime, 'Can not finish before start time');
        require(isFinish == false, 'This sale has already been launched');
        require(isRefund == false, 'Can not launch during refund process');

        uint256 tokensForSale = ethRaised * (pool.saleRate) / (10**18) / (10**(18-tokenDecimals));
        uint256 tokensForLiquidity = ethRaised * pool.listingRate * pool.liquidityPortion / 100 / (10**18) / (10**(18-tokenDecimals));
        tokensForLiquidity = tokensForLiquidity - (tokensForLiquidity * fee / 100);
        uint256 tokensForFee = fee * (tokensForSale + tokensForLiquidity) / 100;

        //add liquidity
        (uint amountToken, uint amountETH, ) = UniswapV2Router02.addLiquidityETH{value : _getLiquidityEth()}(address(tokenInstance),tokensForLiquidity, tokensForLiquidity, _getLiquidityEth(), owner(), block.timestamp + 600);
        require(amountToken == tokensForLiquidity && amountETH == _getLiquidityEth(), "Error: Method addLiquidityETH failed.");
        emit Liquified(address(tokenInstance), address(UniswapV2Router02), UniswapV2Factory.getPair(address(tokenInstance), weth));

        //take the Fees
        uint256 teamShareEth = _getFeeEth();
        payable(teamWallet).transfer(teamShareEth);

        tokenInstance.transfer(teamWallet, tokensForFee);

        //withrawal eth
        uint256 ownerShareEth = _getOwnerEth();
        if (ownerShareEth > 0) {
            payable(creatorWallet).transfer(ownerShareEth);
        }

        //If HC is not reached, burn or refund the remainder
        if (ethRaised < pool.hardCap) {
            uint256 remainder = _getTokenDeposit() - (tokensForSale + tokensForLiquidity + tokensForFee);
            if(burnTokens == true){
                tokenInstance.transfer(0x000000000000000000000000000000000000dEaD, remainder);
                emit BurntRemainder(msg.sender, remainder);
            } else {
                tokenInstance.transfer(creatorWallet, remainder);
                emit RefundedRemainder(msg.sender, remainder);
            }
        }

        //updating the boolean prevents from using the function again ever
        isFinish = true;
    }

    function disableWhitelist() external onlyOwner{
        require(isWhitelist, 'Presale: Whitelist is already disabled.');

        isWhitelist = false;
    }

    /*
    * If requirements are passed, updates user's token balance based on their eth contribution
    */
    function buyTokens(address _contributor) public payable onlyActive {
        require(isDeposit, 'No tokens are deposited to the contract');

        uint256 weiAmount = msg.value;
        _checkSaleRequirements(_contributor, weiAmount);
        uint256 tokensAmount = _getUserTokens(ethContribution[msg.sender]);
        ethRaised += weiAmount;
        presaleTokens -= tokensAmount;
        ethContribution[msg.sender] += weiAmount;
        emit Bought(_msgSender(), tokensAmount);
    }

    /*
    * Checks whether a user passes token purchase requirements, called internally on buyTokens function
    */
    function _checkSaleRequirements(address _beneficiary, uint256 _amount) internal view { 
        if(isWhitelist){
            require(whitelists[_msgSender()], 'Presale: User not Whitelisted.');
        }

        require(_beneficiary != address(0), 'transfer to 0 address.');
        require(_amount != 0, "weiAmount is 0");
        require(_amount >= pool.minBuy, 'minBuy is not met.');
        require(_amount + ethContribution[_beneficiary] <= pool.maxBuy, 'Max buy limit exceeded.');
        require(ethRaised + _amount <= pool.hardCap, 'Hard cap is already reached.');
        this;
    }

    /*
    * Internal functions, called when calculating balances
    */
    function _getUserTokens(uint256 _amount) internal view returns (uint256){
        return _amount * (pool.saleRate) / (10 ** 18) / (10**(18-tokenDecimals));
    }

    function _getLiquidityTokensDeposit() internal view returns (uint256) {
        uint256 value = pool.hardCap * pool.listingRate * pool.liquidityPortion / 100;
        value = value - (value * fee / 100);
        return value / (10**18) / (10**(18-tokenDecimals));
    }
    function _getFeeEth() internal view returns (uint256) {
        return (ethRaised * fee / 100);
    }

    function _getLiquidityEth() internal view returns (uint256) {
        uint256 etherFee = _getFeeEth();
        return((ethRaised - etherFee) * pool.liquidityPortion / 100);
    }

    function _getOwnerEth() internal view returns (uint256) { 
        uint256 etherFee = _getFeeEth();
        uint256 liquidityEthFee = _getLiquidityEth();
        return(ethRaised - (etherFee + liquidityEthFee));
    }
    function _getTokenDeposit() internal view returns (uint256){
        uint256 tokensForSale = pool.hardCap * pool.saleRate / (10**18) / (10**(18-tokenDecimals));
        uint256 tokensForLiquidity = _getLiquidityTokensDeposit();
        uint256 tokensForFee = fee * (tokensForSale + tokensForLiquidity) / 100;
        return(tokensForSale + tokensForLiquidity + tokensForFee);
    }
}   