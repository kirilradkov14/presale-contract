// SPDX-License-Identifier: Unlicensed
// https://github.com/kirilradkov14
pragma solidity ^0.8.19;

import "./proxy/Initializable.sol";
import "./utils/Address.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapv2Router02.sol";
import "./interfaces/IERC20Metadata.sol";

contract Presale is Initializable {
    using Address for address payable;

    address constant WETH = "0x000000000000000000000000000000000000dEaD";
    address constant DEAD = "0x000000000000000000000000000000000000dEaD";

    struct Pool {
        bool burnUnsold;
        uint8 tokenDecimals;
        address creator;
        uint256 presaleTokens;
        uint256 ethRaised;
        uint64 startTime;
        uint64 endTime;
        uint8 liquidityPortion;
        uint8 status;
        uint256 saleRate;
        uint256 listingRate;
        uint256 hardCap;
        uint256 softCap;
        uint256 maxBuy;
        uint256 minBuy;
    }

    struct Arguments {
        address tokenAddress;
        address uniswapv2Router;
        address uniswapv2Factory;
        bool burnUnsold;
        uint8 liquidityPortion;
        uint64 startTime;
        uint64 endTime;
        uint256 saleRate;
        uint256 listingRate;
        uint256 hardCap;
        uint256 softCap;
        uint256 maxBuy;
        uint256 minBuy;
    }

    IERC20 public token;
    Pool public pool;
    IUniswapV2Factory public UniswapV2Factory;
    IUniswapV2Router02 public UniswapV2Router02;

    mapping(address => uint256) public ethContribution;

    modifier onlyCreator() {
        require(msg.sender == pool.creator, "Not the creator");
        _;
    }

    modifier onlyActive {
        require(block.timestamp >= pool.startTime, "Sale must be active.");
        require(block.timestamp <= pool.endTime, "Sale must be active.");
        _;
    }

    modifier onlyInactive {
        require(
            block.timestamp < pool.startTime || 
            block.timestamp > pool.endTime || 
            pool.ethRaised >= pool.hardCap, "Sale must be inactive."
            );
        _;
    }

    modifier onlyRefund {
        require(
            pool.status == 3 || 
            (block.timestamp > pool.endTime && pool.ethRaised <= pool.hardCap), "Refund unavailable."
            );
        _;
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

    function initialize(Arguments calldata args) external payable initializer{
        require(args.startTime >= block.timestamp, "Invalid start time.");
        require(args.endTime > block.timestamp, "Invalid end time.");
        require(args.softCap >= args.hardCap / 2, "SC must be >= HC/2.");
        require(args.liquidityPortion >= 30, "Liquidity must be >=30.");
        require(args.liquidityPortion <= 100, "Invalid liquidity.");
        require(args.minBuy < args.maxBuy, "Min buy must greater than max.");
        require(args.minBuy > 0, "Min buy must exceed 0.");
        require(args.saleRate > 0, "Invalid sale rate.");
        require(args.listingRate > 0, "Invalid listing rate.");

        token = IERC20(args.tokenAddress);

        pool memory newPool = Pool(
            args.burnUnsold,
            IERC20Metapool(address(token)).decimals(),
            msg.sender,
            0,
            0,
            args.startTime,
            args.endTime,
            args.liquidityPortion,
            1,
            args.saleRate,
            args.listingRate,
            args.hardCap,
            args.softCap,
            args.maxBuy,
            args.minBuy
        );

        pool = newPool;
        UniswapV2Router02 = IUniswapV2Router02(args.uniswapv2Router);
        UniswapV2Factory = IUniswapV2Factory(args.uniswapv2Factory);
        require(UniswapV2Factory.getPair(address(token), WETH) == address(0), "IUniswap: Pool exists.");

        token.approve(args.uniswapv2Router, token.totalSupply());
    }


    function depositTokens() external onlyCreator {
        require(pool.status == 1, "Unable to deposit tokens");
        pool.status = 2;

        uint256 tokensForSale = pool.hardCap * (pool.saleRate) / (10**18) / (10**(18 - pool.tokenDecimals));
        presaleTokens = tokensForSale;
        uint256 totalDeposit = _getTokenDeposit();

        require(token.transferFrom(msg.sender, address(this), totalDeposit), "Deposit failed.");
        emit Deposited(msg.sender, totalDeposit);
    }

    /*
    * Finish the sale - Create Uniswap v2 pair, add liquidity, take fees, withrdawal funds, burn/refund unused tokens
    */
    function finishSale() external onlyCreator onlyInactive{
        require(status < 3, "Unable to finalize");
        require(pool.ethRaised >= pool.softCap, "Soft Cap is not met.");
        require(block.timestamp > pool.startTime, "Can not finish before start");
        pool.status = 4;

        uint256 tokensForSale = pool.ethRaised * (pool.saleRate) / (10**18) / (10**(18 - pool.tokenDecimals));
        uint256 tokensForLiquidity = pool.ethRaised * pool.listingRate * pool.liquidityPortion / 100;
        tokensForLiquidity = tokensForLiquidity / (10**18) / (10**(18 - pool.tokenDecimals));
        
        //add liquidity
        (uint amountToken, uint amountETH, ) = UniswapV2Router02.addLiquidityETH{value : _getLiquidityEth()}(
            address(token),
            tokensForLiquidity, 
            tokensForLiquidity, 
            _getLiquidityEth(), 
            creator, 
            block.timestamp + 600
            );
        require(amountToken == tokensForLiquidity && amountETH == _getLiquidityEth(), "Failed to liquify");

        emit Liquified(
            address(token), 
            address(UniswapV2Router02), 
            UniswapV2Factory.getPair(address(token), 
            WETH)
            );

        //withrawal eth
        uint256 ownerShareEth = _getOwnerEth();
        if (ownerShareEth > 0) {
            payable(creator).sendValue(ownerShareEth);
        }

        //If HC is not reached, burn or refund the remainder
        if (pool.ethRaised < pool.hardCap) {
            uint256 remainder = _getTokenDeposit() - (tokensForSale + tokensForLiquidity);
            if(burnTokens == true){
                require(token.transfer(
                    DEAD, 
                    remainder), "Burn failed"
                    );
                emit BurntRemainder(msg.sender, remainder);
            } else {
                require(token.transfer(creator, remainder), "Refund failed");
                emit RefundedRemainder(msg.sender, remainder);
            }
        }
    }

    function cancelSale() external onlyCreator onlyActive {
        require(pool.status < 3, "Unable to cancel");
        pool.status = 3;
        pool.endTime = 0;

        if (token.balanceOf(address(this)) > 0) {
            uint256 tokenDeposit = _getTokenDeposit();
            require(token.transfer(msg.sender, tokenDeposit), "Unable to retrieve tokens");
            emit Withdraw(msg.sender, tokenDeposit);
        }
        emit Canceled(msg.sender, address(token), address(this));
    }
    
    /*
    * Refunds the Eth to participents
    */
    function refund() external onlyInactive onlyRefund{
        uint256 refundAmount = ethContribution[msg.sender];

        if (address(this).balance >= refundAmount) {
            if (refundAmount > 0) {
                ethContribution[msg.sender] = 0;
                payable(msg.sender).sendValue(refundAmount);
                emit Refunded(msg.sender, refundAmount);
            }
        }
    }

    /*
    * Withdrawal tokens on refund
    */
    function withrawTokens() external onlyCreator onlyInactive onlyRefund {
        if (token.balanceOf(address(this)) > 0) {
            uint256 tokenDeposit = _getTokenDeposit();
            require(token.transfer(msg.sender, tokenDeposit), "Withdraw failed.");
            emit Withdraw(msg.sender, tokenDeposit);
        }
    }

    /*
    * If requirements are passed, updates user"s token balance based on their eth contribution
    */
    function buyTokens(address _contributor) public payable onlyActive {
        require(pool.status == 2, "Tokens not deposited");

        uint256 weiAmount = msg.value;
        _validatePurchase(_contributor, weiAmount);
        uint256 tokensAmount = _getUserTokens(ethContribution[msg.sender]);
        pool.ethRaised += weiAmount;
        pool.presaleTokens -= tokensAmount;
        ethContribution[msg.sender] += weiAmount;
        emit Bought(_msgSender(), tokensAmount);
    }

    /*
    * Checks whether a user passes token purchase requirements, called internally on buyTokens function
    */
    function _validatePurchase(address _beneficiary, uint256 _amount) internal view { 
        require(_beneficiary != address(0), "Transfer to 0 address.");
        require(_amount != 0, "Wei Amount is 0");
        require(_amount >= pool.minBuy, "Min buy is not met.");
        require(_amount + ethContribution[_beneficiary] <= pool.maxBuy, "Max buy limit exceeded.");
        require(pool.ethRaised + _amount <= pool.hardCap, "HC Reached.");
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
        return value / (10**18) / (10**(18-tokenDecimals));
    }

    function _getLiquidityEth() internal view returns (uint256) {
        return(pool.ethRaised * pool.liquidityPortion / 100);
    }

    function _getOwnerEth() internal view returns (uint256) { 
        uint256 liquidityEthFee = _getLiquidityEth();
        return(pool.ethRaised - liquidityEthFee);
    }
    
    function _getTokenDeposit() internal view returns (uint256){
        uint256 tokensForSale = pool.hardCap * pool.saleRate / (10**18) / (10**(18-tokenDecimals));
        uint256 tokensForLiquidity = _getLiquidityTokensDeposit();
        return(tokensForSale + tokensForLiquidity);
    }
}