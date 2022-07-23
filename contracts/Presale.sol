
pragma solidity ^0.8.4;
// SPDX-License-Identifier: Unlicensed
// A+G = VNL
// https://github.com/kirilradkov14

import './IERC20.sol';
import './SafeMath.sol';
import './Ownable.sol';
import './Whitelist.sol';

/*
* !=======================================! Presale contract !=======================================!
*/
contract Presale is Ownable, Whitelist{
    using SafeMath for uint256;
    using SafeMath for uint8;

    IERC20  public tokenInstance;
    IUniswapV2Factory UniswapV2Factory;
    IUniswapV2Router02 UniswapV2Router02;

    address creatorWallet;
    uint8 tokenDecimals;
    uint8 fee;

    bool isInit;
    bool isDeposit;
    bool isRefund;
    bool isFinish;
    bool burnTokens;
    bool isWhitelist;

    struct Vesting {
        uint256 lastCliff;
        uint256 cycleTime;
        uint8 initialRelease;
        uint8 cliffRelease;
    }

    struct Pool {
        uint256 softCap;
        uint256 hardCap;
        uint256 minBuy;
        uint256 maxBuy;
        uint8 liquidityPortion;
        uint256 saleRate;
        uint256 listingRate;
        uint256 startTime;
        uint256 endTime;    
    }

    struct Balances{
        uint256 presaleTokens;
        uint256 ethRaised;
    }

    struct User {
        uint256 ethContribution;
        uint256 userTokens;
        uint256 unlockedTokens;
    }
    
    Balances public bal;
    Pool public pool;
    Vesting public vesting;

    mapping (address => User) public users;


    /*
    * !=======================================! Modifiers !=======================================!
    */
    // presale is running
    modifier onlyActive {
        require(block.timestamp >= pool.startTime && block.timestamp <= pool.endTime, 'Presale: ICO must be active.');
        _;
    }
    //presale not started yet, has finished or hardCap reached
    modifier onlyInactive {
        require(block.timestamp < pool.startTime || block.timestamp > pool.endTime || bal.ethRaised >= pool.hardCap, 'Presale: ICO must be inactive.');
        _;
    }           
    //requires tokens sent to address this
    modifier onlyDeposit {
        require(isDeposit, 'Presale: No tokens are deposited to the contract');
        _;
    }
    modifier onlyRefund {
        require(isRefund == true || (block.timestamp > pool.endTime && bal.ethRaised <= pool.hardCap), 'Presale: Refund unavailable');
        _;
    }

    /*
    *  !=======================================! Events !=======================================!
    */
    event bought (address _buyer, uint256 _tokenAmount);
    event refunded (address _refunder, uint256 _tokenAmount);
    event claimed (address _participent, uint256 _tokenAmount);
    event remainderRefunded(address _initiator, uint256 _amount);
    event remainderBurnt (address _initiator, uint256 _amount);
    event liquified(address _token, address _router, address _pair);
    event canceled (address _inititator, address _token, address _presale);
    event deposited(address _initiator, uint256  _tokensForSale, uint256 _tokensForLiquidity, uint256 _tokensForFee, uint256 _totalDeposit);
    event withdraw(address _creator, uint256 _amount);
    

    constructor (
        address payable _creatorWallet, 
        IERC20 _tokenInstance, 
        uint8 _tokenDecimals, 
        address _uniswapv2Router, 
        address _uniswapv2Factory, 
        bool _burnTokens,
        bool _isWhitelist,
        uint8 _initialRelease,
        uint8 _cliffRelease,
        uint256 _cycleTime 
        ) {

        require(_creatorWallet != address(0), 'Presale: creatorWallet must be 0 address.');
        require(address(_tokenInstance) != address(0), 'Presale: creatorWallet can not be 0 address.');
        require(_uniswapv2Router != address(0), 'Presale: Router must be different from 0 address');
        require(_uniswapv2Factory != address(0), 'Presale: Factory must be different from 0 address');
        require(_tokenDecimals >= 0 && _tokenDecimals <= 18, 'Presale: Invalid value for decimals');
        require(_initialRelease.add(_cliffRelease) <= 100, "Presale: Initial release and cliff release must not exceed 100.");
        require(_cycleTime > 60, "Presale: Cycle time must be more than 60");

        isInit = false;
        isDeposit = false;
        isFinish = false;
        isRefund = false;
        bal.ethRaised = 0;

        vesting.initialRelease = _initialRelease;
        vesting.cliffRelease = _cliffRelease;
        vesting.cycleTime = _cycleTime;

        burnTokens = _burnTokens;
        tokenInstance = _tokenInstance;
        creatorWallet = _creatorWallet;
        tokenDecimals =  _tokenDecimals;
        isWhitelist = _isWhitelist;
        fee = 2;
        UniswapV2Router02 = IUniswapV2Router02(_uniswapv2Router);
        UniswapV2Factory = IUniswapV2Factory(_uniswapv2Factory);

        tokenInstance.approve(_uniswapv2Router, tokenInstance.totalSupply());
        require(UniswapV2Factory.getPair(address(tokenInstance), 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6) == address(0), "Presale: Uniswap pool already exists.");
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
        ) public onlyOwner onlyInactive {        

        require(isInit == false, 'Sale is already initialized');
        require(_startTime >= block.timestamp, 'Start time must exceed current timestamp.');
        require(_endTime > block.timestamp, 'End time must exceed current timestamp');
        require(_softCap >= _hardCap.div(2), 'Soft cap must be at least 50% of hardcap.');
        require(_liquidityPortion >= 30 && _liquidityPortion <= 100, 'At least 30% and no more than 100% of ethers should go to liquidity .');
        require(_minBuy < _maxBuy && _minBuy > 0, 'Invalid value for minBuy.');
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
    * Fallback function reverts ethers sent to this address whenever requirements are not met
    */
    receive () external payable {
        if(block.timestamp >= pool.startTime && block.timestamp <= pool.endTime){
            buyTokens(_msgSender());
        } else {
            revert('Pre-Sale is closed');
        }
    }

    /*
    * Once called the owner deposits tokens into pool
    */
    function deposit () external onlyOwner {
        require(isDeposit == false, 'Tokens already deposited to the pool.');
        require(isInit == true, 'Pool not initialized yet');

        uint256 tokensForSale = pool.hardCap.mul(pool.saleRate).div(10**18).div(10**(18-tokenDecimals));
        uint256 tokensForLiquidity = _getLiquidityTokensDeposit();
        uint256 tokensForFee = fee.mul(tokensForSale.add(tokensForLiquidity)).div(100);
        uint256 totalDeposit = tokensForSale.add(tokensForLiquidity).add(tokensForFee);

        tokenInstance.transferFrom(msg.sender, address(this), tokensForSale.add(tokensForLiquidity).add(tokensForFee));
        bal.presaleTokens = tokensForSale;

        emit deposited(msg.sender, tokensForSale, tokensForLiquidity, tokensForFee, totalDeposit);

        //updating the boolean prevents from using the function again ever
        isDeposit = true;
    }

    /*
    * The owner can decide to close the sale if it is still active
    NOTE: Creator may call this function even if the Hard Cap is reached, to prevent it use:
     require(bal.ethRaised < pool.hardCap)
    */
    function cancelSale() external onlyOwner onlyActive {
        require(isFinish == false, 'This sale has already finished.');
        pool.endTime = 0;
        isRefund = true;

        if (tokenInstance.balanceOf(address(this)) > 0) {
            uint256 tokenDeposit = _getTokenDeposit();
            tokenInstance.transfer(msg.sender, tokenDeposit);
            emit withdraw(msg.sender, tokenDeposit);
        }
        emit canceled(msg.sender, address(tokenInstance), address(this));
    }

    /*
    * If requirements are passed, updates user's token balance based on their eth contribution
    */
    function buyTokens(address _contributor) public onlyActive onlyDeposit payable {
        uint256 weiAmount = msg.value;
        _checkSaleRequirements(_contributor, weiAmount);
        uint256 tokensAmount = _getUserTokens(users[msg.sender].ethContribution);
        bal.ethRaised = bal.ethRaised.add(weiAmount);
        bal.presaleTokens = bal.presaleTokens.sub(tokensAmount);
        users[msg.sender].ethContribution = users[msg.sender].ethContribution.add(weiAmount);
        emit bought(_msgSender(), tokensAmount);
    }

    /*
    * Allows participents to claim the tokens they purchased when vesting mechanism is disabled 
    */
    function claimTokens() external onlyInactive {
        require(isFinish == true, 'Presale. Sale not finalized');
        require(!isRefund, 'Presale. Cannot claim during refund.');

        //calculate unlocked balanace
        uint256 unlocked = _getUnlockedTokens(msg.sender);
        tokenInstance.transfer(msg.sender, unlocked);
        users[msg.sender].unlockedTokens = users[msg.sender].unlockedTokens.sub(unlocked);
        users[msg.sender].ethContribution = 0;
        emit claimed(msg.sender, unlocked);
    }

    /*
    * Refunds the Eth to participents
    */
    function refund () public onlyInactive onlyRefund{
        uint256 refundAmount = users[msg.sender].ethContribution;
        
        if (address(this).balance >= refundAmount) {
            if (refundAmount > 0) {
                address payable refunder = payable(msg.sender);
                refunder.transfer(refundAmount);
                emit refunded(refunder, refundAmount);
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
            emit withdraw(msg.sender, tokenDeposit);
        }
    }

    /*
    * Finish the sale - Create Uniswap v2 pair, add liquidity, take fees, withrdawal funds, burn unused tokens
    */
    function finishSale() external onlyOwner onlyInactive{
        require(bal.ethRaised >= pool.softCap, 'Presale: Soft Cap is not met');
        require(block.timestamp > pool.startTime, 'Presale: Can not finish before start time');
        require(isFinish == false, 'Presale: This sale has already been launched');
        require(isRefund == false, 'Presale: Can not launch during refund process');

        uint256 tokensForSale = bal.ethRaised.mul(pool.saleRate).div(10**18).div(10**(18-tokenDecimals));
        uint256 tokensForLiquidity = bal.ethRaised.mul(pool.listingRate).mul(pool.liquidityPortion).div(100).div(10**18).div(10**(18-tokenDecimals));
        tokensForLiquidity = tokensForLiquidity.sub(tokensForLiquidity.mul(fee).div(100));
        uint256 tokensForFee = fee.mul(tokensForSale.add(tokensForLiquidity)).div(100);

        //add liquidity
        (uint amountToken, uint amountETH, ) = UniswapV2Router02.addLiquidityETH{value : _getLiquidityEth()}(address(tokenInstance),tokensForLiquidity, tokensForLiquidity, _getLiquidityEth(), owner(), block.timestamp + 600);
        require(amountToken == tokensForLiquidity && amountETH == _getLiquidityEth(), "Error: Method addLiquidityETH failed.");
        emit liquified(address(tokenInstance), address(UniswapV2Router02), UniswapV2Factory.getPair(address(tokenInstance), 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6));

        //take the Fees
        uint256 teamShareEth = _getFeeEth();
        payable(0xced1cB80C96D4b98DbcBbD20af69A5396Ec3507C).transfer(teamShareEth);

        tokenInstance.transfer(0xced1cB80C96D4b98DbcBbD20af69A5396Ec3507C, tokensForFee);

        //withrawal eth
        uint256 ownerShareEth = _getOwnerEth();
        if (ownerShareEth > 0) {
            payable(creatorWallet).transfer(ownerShareEth);
        }

        //If HC is not reached, burn or refund the remainder
        if (bal.ethRaised < pool.hardCap) {
            uint256 currentBal = _getTokenDeposit();
            uint256 remainder = currentBal.sub(tokensForSale.add(tokensForLiquidity).add(tokensForFee));
            if(burnTokens == true){
                tokenInstance.transfer(0x000000000000000000000000000000000000dEaD, remainder);
                emit remainderBurnt(msg.sender, remainder);
            } else {
                tokenInstance.transfer(creatorWallet, remainder);
                emit remainderRefunded(msg.sender, remainder);
            }
        }

        vesting.lastCliff = block.timestamp;
        //updating the boolean prevents from using the function again
        isFinish = true;
    }

    /*
    * Owner disables whitelist
    */
    function disableWhitelist() external onlyOwner onlyActive{
        require(isWhitelist, 'Presale: Whitelist is disabled.');

        isWhitelist = false;
    }

    /*
    * Checks whether a user passes token purchase requirements, called internally on buyTokens function
    */
    function _checkSaleRequirements (address _beneficiary, uint256 _amount) internal view { 
        if (isWhitelist) {
            require(whitelists[_msgSender()] == true, "Presale: User not whitelisted");
        }

        require(_beneficiary != address(0), 'Presale: Transfer to 0 address.');
        require(_amount != 0, "Presale: weiAmount is 0");
        require(_amount >= pool.minBuy, 'Presale: minBuy is not met.');
        require(_amount.add(users[_beneficiary].ethContribution) <= pool.maxBuy, 'Presale: Max buy limit exceeded.');
        require(bal.ethRaised.add(_amount) <= pool.hardCap, 'Presale: Hard cap is already reached.');
        this;
    }

    /*
    * Internal functions, called when calculating balances
    */
    function _getUserTokens(uint256 _amount) internal view returns (uint256){
        return _amount.mul(pool.saleRate).div(10 ** 18).div(10**(18-tokenDecimals));
    }

    /*
    * Calculates unlocked balance
    */
    function _getUnlockedTokens(address _user) internal returns (uint256){
        if (users[msg.sender].ethContribution > 0){
            users[msg.sender].userTokens = _getUserTokens(users[_user].ethContribution);
            users[_user].unlockedTokens = users[msg.sender].userTokens.mul(vesting.initialRelease).div(100);
        }

        if (block.timestamp >= vesting.lastCliff.add(vesting.cycleTime)) {
            vesting.lastCliff = block.timestamp;

            users[_user].unlockedTokens = users[_user].unlockedTokens.add(users[msg.sender].userTokens.mul(vesting.cliffRelease).div(100));
        }

        return (users[_user].unlockedTokens);
    }

    function _getLiquidityTokensDeposit() internal view returns (uint256) {
        uint256 value = pool.hardCap.mul(pool.listingRate).mul(pool.liquidityPortion).div(100);
        value = value.sub(value.mul(fee).div(100));
        return value.div(10**18).div(10**(18-tokenDecimals));
    }

    function _getFeeEth() internal view returns (uint256) {
        return ((bal.ethRaised.mul(fee)).div(100));
    }

    function _getLiquidityEth() internal view returns (uint256) {
        uint256 etherFee = _getFeeEth();
        return(((bal.ethRaised.sub(etherFee)).mul(pool.liquidityPortion)).div(100));
    }

    function _getOwnerEth() internal view returns (uint256) { 
        uint256 etherFee = _getFeeEth();
        uint256 liquidityEthFee = _getLiquidityEth();
        return(bal.ethRaised.sub(etherFee.add(liquidityEthFee)));
    }

    function _getTokenDeposit() internal view returns (uint256){
        uint256 tokensForSale = pool.hardCap.mul(pool.saleRate).div(10**18).div(10**(18-tokenDecimals));
        uint256 tokensForLiquidity = _getLiquidityTokensDeposit();
        uint256 tokensForFee = fee.mul(tokensForSale.add(tokensForLiquidity)).div(100);
        return(tokensForSale.add(tokensForLiquidity).add(tokensForFee));
    }

    /*
    *   testing functions
    */
    function getUserTokens() public view returns (uint256){
        return users[msg.sender].ethContribution.mul(pool.saleRate).div(10 ** 18).div(10**(18-tokenDecimals));
    }

    function getTokenDeposit() public view returns (uint256){
        uint256 tokensForSale = pool.hardCap.mul(pool.saleRate).div(10**18).div(10**(18-tokenDecimals));
        uint256 tokensForLiquidity = _getLiquidityTokensDeposit();
        uint256 tokensForFee = fee.mul(tokensForSale.add(tokensForLiquidity)).div(100);
        return(tokensForSale.add(tokensForLiquidity).add(tokensForFee));
    }
}   
/*
* !=======================================! Interfaces !=======================================!
*/
interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IUniswapV2Router02 {
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}
