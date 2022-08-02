pragma solidity ^0.8.4;
// SPDX-License-Identifier: Unlicensed
// A+G = VNL
// https://github.com/kirilradkov14
import './Ownable.sol';
import './Whitelist.sol';

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IUniswapV2Router02 {
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

contract Presale is Ownable, Whitelist {

    bool isInit;
    bool isDeposit;
    bool isRefund;
    bool isFinish;
    bool burnTokens;
    bool isWhitelist;
    address creatorWallet;
    address teamWallet;
    address weth;
    uint8 constant fee = 2;
    uint8 tokenDecimals;
    uint256 presaleTokens;
    uint256 ethRaised;

    struct Pool {
        uint64 startTime;
        uint64 endTime;
        uint8 liquidityPortion;
        uint256 saleRate;
        uint256 listingRate;
        uint256 hardCap;
        uint256 softCap;
        uint256 maxBuy;
        uint256 minBuy;
    }

    IERC20 public tokenInstance;
    IUniswapV2Factory UniswapV2Factory;
    IUniswapV2Router02 UniswapV2Router02;
    Pool pool;

    mapping(address => uint256) public ethContribution;


    modifier onlyActive {
        require(block.timestamp >= pool.startTime);
        require(block.timestamp <= pool.endTime, 'Presale: Sale must be active.');
        _;
    }

    modifier onlyInactive {
        require(block.timestamp < pool.startTime || block.timestamp > pool.endTime || ethRaised >= pool.hardCap, 'Presale: Sale must be inactive.');
        _;
    }

    modifier onlyRefund {
        require(isRefund == true || (block.timestamp > pool.endTime && ethRaised <= pool.hardCap), 'Presale: Refund unavailable');
        _;
    }

    constructor(
        IERC20 _tokenInstance, 
        uint8 _tokenDecimals, 
        address _uniswapv2Router, 
        address _uniswapv2Factory,
        address _teamWallet,
        address _weth,
        bool _burnTokens,
        bool _isWhitelist
        ) {

        require(_uniswapv2Router != address(0), 'Presale: Router must be different from 0 address');
        require(_uniswapv2Factory != address(0), 'Presale: Factory must be different from 0 address');
        require(_tokenDecimals >= 0, 'Presale: Decimals can not be negative');
        require(_tokenDecimals <= 18, 'Presale: Decimals must not exceed 18');

        isInit = false;
        isDeposit = false;
        isFinish = false;
        isRefund = false;
        ethRaised = 0;

        teamWallet = _teamWallet;
        weth = _weth;
        burnTokens = _burnTokens;
        isWhitelist = _isWhitelist;
        tokenInstance = _tokenInstance;
        creatorWallet = address(payable(msg.sender));
        tokenDecimals =  _tokenDecimals;
        UniswapV2Router02 = IUniswapV2Router02(_uniswapv2Router);
        UniswapV2Factory = IUniswapV2Factory(_uniswapv2Factory);

        require(UniswapV2Factory.getPair(address(tokenInstance), weth) == address(0), "IUniswap: Uniswap pool already exist.");

        tokenInstance.approve(_uniswapv2Router, tokenInstance.totalSupply());
    }

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

    /*
    * Reverts ethers sent to this address whenever requirements are not met
    */
    receive() external payable {
        if(block.timestamp >= pool.startTime && block.timestamp <= pool.endTime){
            buyTokens(_msgSender());
        } else {
            revert('Presale is closed');
        }
    }

    /*
    * Initiates the arguments of the sale
    @dev arguments must be pa   ssed in wei (amount*10**18)
    */
    function initSale(
        uint64 _startTime,
        uint64 _endTime,
        uint8 _liquidityPortion,
        uint256 _saleRate, 
        uint256 _listingRate,
        uint256 _hardCap,
        uint256 _softCap,
        uint256 _maxBuy,
        uint256 _minBuy
        )external onlyOwner onlyInactive {        

        require(isInit == false, 'Presale: Sale no initialized');
        require(_startTime >= block.timestamp, 'Presale: Start time must exceed current timestamp.');
        require(_endTime > block.timestamp, 'Presale: End time must exceed current timestamp');
        require(_softCap >= _hardCap / 2, 'Presale: Soft cap must be at least 50% of hard cap.');
        require(_liquidityPortion >= 30, 'Presale: Liquidity portion must be at least 30.');
        require(_liquidityPortion <= 100, 'Presale: Liquidity portion must not exceed 100.');
        require(_minBuy < _maxBuy, 'Presale: Min buy must be less than max buy.');
        require(_minBuy > 0, 'Presale: Min buy must exceed 0.');
        require(_saleRate > 0, 'Presale: Token - Ether ratio must be more than 0.');
        require(_listingRate > 0, 'Presale: Token - Ether ratio must be more than 0.');

        Pool memory newPool = Pool(_startTime, _endTime, _liquidityPortion, _saleRate, _listingRate, _hardCap, _softCap, _maxBuy, _minBuy);
        pool = newPool;
        
        isInit = true;
    }

    /*
    * Once called the owner deposits tokens into pool
    */
    function deposit() external onlyOwner {
        require(!isDeposit, 'Presale: Tokens already deposited to the pool.');
        require(isInit, 'Presale: Pool not initialized yet.');

        uint256 tokensForSale = pool.hardCap * (pool.saleRate) / (10**18) / (10**(18-tokenDecimals));
        presaleTokens = tokensForSale;
        uint256 totalDeposit = _getTokenDeposit();

        require(tokenInstance.transferFrom(msg.sender, address(this), totalDeposit), 'Presale: Deposit failed.');
        emit Deposited(msg.sender, totalDeposit);

        //updating the boolean prevents from using the function again
        isDeposit = true;
    }

    /*
    * Finish the sale - Create Uniswap v2 pair, add liquidity, take fees, withrdawal funds, burn/refund unused tokens
    */
    function finishSale() external onlyOwner onlyInactive{
        require(ethRaised >= pool.softCap, 'Presale: Soft Cap is not met.');
        require(block.timestamp > pool.startTime, 'Presale: Can not finish before start time.');
        require(!isFinish, 'Presale: This sale has already been launched.');
        require(!isRefund, 'Presale: Can not launch during refund process.');

        //get the used amount of tokens
        uint256 tokensForSale = ethRaised * (pool.saleRate) / (10**18) / (10**(18-tokenDecimals));
        uint256 tokensForLiquidity = ethRaised * pool.listingRate * pool.liquidityPortion / 100 / (10**18) / (10**(18-tokenDecimals));
        tokensForLiquidity = tokensForLiquidity - (tokensForLiquidity * fee / 100);
        uint256 tokensForFee = fee * (tokensForSale + tokensForLiquidity) / 100;

        //add liquidity
        (uint amountToken, uint amountETH, ) = UniswapV2Router02.addLiquidityETH{value : _getLiquidityEth()}(address(tokenInstance),tokensForLiquidity, tokensForLiquidity, _getLiquidityEth(), owner(), block.timestamp + 600);
        require(amountToken == tokensForLiquidity && amountETH == _getLiquidityEth(), "IUniswap: Method addLiquidityETH failed.");
        emit Liquified(address(tokenInstance), address(UniswapV2Router02), UniswapV2Factory.getPair(address(tokenInstance), weth));

        //take the Fees
        uint256 teamShareEth = _getFeeEth();
        payable(teamWallet).transfer(teamShareEth);

        require(tokenInstance.transfer(teamWallet, tokensForFee), 'Presale: Token transfer fee failed.');

        //withrawal eth
        uint256 ownerShareEth = _getOwnerEth();
        if (ownerShareEth > 0) {
            payable(creatorWallet).transfer(ownerShareEth);
        }

        //If HC is not reached, burn or refund the remainder
        if (ethRaised < pool.hardCap) {
            uint256 remainder = _getTokenDeposit() - (tokensForSale + tokensForLiquidity + tokensForFee);
            if(burnTokens == true){
                require(tokenInstance.transfer(0x000000000000000000000000000000000000dEaD, remainder), 'Presale: Remainder token burn failed.');
                emit BurntRemainder(msg.sender, remainder);
            } else {
                require(tokenInstance.transfer(creatorWallet, remainder), 'Presale: Remainder token refund failed.');
                emit RefundedRemainder(msg.sender, remainder);
            }
        }

        //updating the boolean prevents from using the function again
        isFinish = true;
    }

    /*
    * The owner can decide to close the sale if it is still active
    NOTE: Creator may call this function even if the Hard Cap is reached, to prevent it use:
     require(ethRaised < pool.hardCap)
    */
    function cancelSale() external onlyOwner onlyActive {
        require(!isFinish, 'Presale: This sale has already finished.');
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
        require(isFinish, 'Presale: Sale is still active.');
        require(!isRefund, 'Presale: Cannot claim during refund.');

        uint256 tokensAmount = _getUserTokens(ethContribution[msg.sender]);
        ethContribution[msg.sender] = 0;
        require(tokenInstance.transfer(msg.sender, tokensAmount), 'Presale: Claim failed.');
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
            require(tokenInstance.transfer(msg.sender, tokenDeposit), 'Presale: Withdraw failed.');
            emit Withdraw(msg.sender, tokenDeposit);
        }
    }

    /*
    * Disables WL
    */
    function disableWhitelist() external onlyOwner{
        require(isWhitelist, 'Presale: Whitelist is already disabled.');

        isWhitelist = false;
    }

    /*
    * If requirements are passed, updates user's token balance based on their eth contribution
    */
    function buyTokens(address _contributor) public payable onlyActive {
        require(isDeposit, 'Presale: No tokens are deposited to the contract.');

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

        require(_beneficiary != address(0), 'Presale: Transfer to 0 address.');
        require(_amount != 0, "Presale: Wei Amount is 0");
        require(_amount >= pool.minBuy, 'Presale: Min buy is not met.');
        require(_amount + ethContribution[_beneficiary] <= pool.maxBuy, 'Presale: Max buy limit exceeded.');
        require(ethRaised + _amount <= pool.hardCap, 'Presale: Hard cap is already reached.');
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