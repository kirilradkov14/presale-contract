// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { IUniswapV2Router02 } from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import { IPresale } from "./interfaces/IPresale.sol";

/**
 * @title Presale contract
 * @notice Create and manage a presales of an ERC20 token
 */
contract Presale is IPresale, Ownable {
    using SafeERC20 for IERC20;
    using Address for address payable;

    /// Scaling factor to maintain precision.
    uint256 constant SCALE = 10**18;

    /** 
     * @notice Presale options
     * @param tokenDeposit Total tokens deposited for sale and liquidity.
     * @param hardCap Maximum Wei to be raised.
     * @param softCap Minimum Wei to be raised to consider the presale successful.
     * @param max Maximum Wei contribution per address.
     * @param min Minimum Wei contribution per address.
     * @param start Start timestamp of the presale.
     * @param end End timestamp of the presale.
     * @param liquidityBps Basis points of funds raised to be allocated to liquidity.
    */ 
    struct PresaleOptions{
        uint256 tokenDeposit;
        uint256 hardCap;
        uint256 softCap;
        uint256 max;
        uint256 min;
        uint112 start;
        uint112 end;
        uint32 liquidityBps;
    }

    /** 
     * @notice Presale pool
     * @param token Address of the token.
     * @param uniswapV2Router02
     * @param tokenBalance Token balance in this contract
     * @param tokensClaimable
     * @param tokensLiquidity
     * @param weiRaised
     * @param weth
     * @param state Current state of the presale {1: Initialized, 2: Active, 3: Canceled, 4: Finalized}.
     * @param options PresaleOptions struct containing configuration for the presale.
    */
    struct Pool {
        IERC20 token;
        IUniswapV2Router02 uniswapV2Router02;
        uint256 tokenBalance;
        uint256 tokensClaimable;
        uint256 tokensLiquidity;
        uint256 weiRaised;
        address weth;
        uint8 state;
        PresaleOptions options;
    }

    mapping(address => uint256) public contributions;

    Pool public pool;

    /// @notice Canceled or NOT softcapped and expired
    modifier onlyRefundable() {
        if(pool.state != 3 || (block.timestamp > pool.options.end && pool.weiRaised < pool.options.softCap)) revert NotRefundable(); 
        _;
    }
    
    /** 
     * @param _weth Address of WETH.
     * @param _token Address of the presale token.
     * @param _uniswapV2Router02 Address of the Uniswap V2 router.
     * @param _options Configuration options for the presale.
    */
    constructor (address _weth, address _token, address _uniswapV2Router02, PresaleOptions memory _options) Ownable(msg.sender) {
        _prevalidatePool(_options);

        pool.uniswapV2Router02 = IUniswapV2Router02(_uniswapV2Router02);
        pool.token = IERC20(_token);
        pool.state = 1;
        pool.weth = _weth;
        pool.options = _options;
    }

    receive() external payable {
        _purchase(msg.sender, msg.value);
    }

    /** 
     * @notice Calling this function deposits tokens into the contract. Contributions are unavailable until this 
     * function is called by the owner of the presale.
     * NOTE This function uses { transferFrom } method from { IERC20 } to handle token deposits into the contract, make sure to approve this contract to spend the required tokens for deposit.
     * @return The amount of tokens deposited.
    */
    function deposit() external onlyOwner returns (uint256) {
        if(pool.state != 1) revert InvalidState(pool.state);
        pool.state = 2;
        
        pool.tokenBalance += pool.options.tokenDeposit;
        pool.tokensLiquidity = _tokensForLiquidity();
        pool.tokensClaimable = _tokensForPresale();

        IERC20(pool.token).safeTransferFrom(msg.sender, address(this), pool.options.tokenDeposit);

        emit Deposit(msg.sender, pool.options.tokenDeposit, block.timestamp);
        return pool.options.tokenDeposit;
    }

    /** 
     * @notice Call this function to finalize a succesfull presale. Calling this function will provide liquidity
     * to Uniswap, withdraw the raised funds and enable token claiming. Tokens can NOT be claimed prior calling this function.
     * @return True if the finalization was successful.
    */
    function finalize() external onlyOwner returns(bool) {
        if(pool.state != 2) revert InvalidState(pool.state);
        if(pool.weiRaised < pool.options.softCap && block.timestamp < pool.options.end) revert SoftCapNotReached();

        pool.state = 4;

        uint256 liquidityWei = _weiForLiquidity();
        _liquify(liquidityWei, pool.tokensLiquidity);
        pool.tokenBalance -= pool.tokensLiquidity;

        uint256 withdrawable = pool.weiRaised - liquidityWei;
        if (withdrawable > 0) payable(msg.sender).sendValue(withdrawable);

        emit Finalized(msg.sender, pool.weiRaised, block.timestamp);
        
        return true;
    }

    /** 
     * @notice Call this function to cancel a presale. Calling this function withdraws deposited tokens and allows contributors 
     * to refund their contributions. Can only cancel NOT finalized presale. 
     * @return True if the cancellation was successful.
    */
    function cancel() external onlyOwner returns(bool){
        if(pool.state > 3) revert InvalidState(pool.state);

        pool.state = 3;

        if (pool.tokenBalance > 0) {
            uint256 amount = pool.tokenBalance;
            pool.tokenBalance = 0;
            IERC20(pool.token).safeTransfer(msg.sender, amount);
        }

        emit Cancel(msg.sender, block.timestamp);

        return true;
    }
    /** 
     * @notice Allows contributors to claim their tokens after the presale is finalized.
     * @return The amount of tokens claimed.
    */
    function claim() external returns (uint256) {
        if(pool.state != 4) revert InvalidState(pool.state);
        if (contributions[msg.sender] == 0) revert NotClaimable();

        uint256 amount = userTokens(msg.sender);
        pool.tokenBalance -= amount;
        contributions[msg.sender] = 0;
        
        IERC20(pool.token).safeTransfer(msg.sender, amount);
        emit TokenClaim(msg.sender, amount, block.timestamp);
        return amount;
    }

    /** 
     * @notice Allows contributors to get a refund when the presale fails or is canceled.
     * @return The amount of Wei refunded.
    */
    function refund() external onlyRefundable returns (uint256) {
        if(contributions[msg.sender] == 0) revert NotRefundable();

        uint256 amount = contributions[msg.sender];

        if(address(this).balance >= amount) {   
            contributions[msg.sender] = 0;
            payable(msg.sender).sendValue(amount);
            emit Refund(msg.sender, amount, block.timestamp);
        }

        return amount;
    }

    /** 
     * @notice Handles token purchase.
     * @param beneficiary The address making the purchase.
     * @param amount The amount of Wei contributed.
    */
    function _purchase(address beneficiary, uint256 amount) private {
        _prevalidatePurchase(beneficiary, amount);

        pool.weiRaised += amount;
        contributions[beneficiary] += amount;
        
        emit Purchase(beneficiary, amount);
    }

    /**
     * @notice Handles liquidity provisioning.
     * @param _weiAmount The amount of Wei to be added to liquidity.
     * @param _tokenAmount The amount of tokens to be added to liquidity.
    */
    function _liquify(uint256 _weiAmount, uint256 _tokenAmount) private {
        (uint amountToken, uint amountETH,) = pool.uniswapV2Router02.addLiquidityETH{value : _weiAmount}(
            address(pool.token),
            _tokenAmount,
            _tokenAmount,
            _weiAmount,
            owner(),
            block.timestamp + 600
        );
        
        if(amountToken != _tokenAmount && amountETH != _weiAmount) revert LiquificationFailed();
    }

    /**
     * @notice Validates the purchase conditions before accepting funds.
     * @param _beneficiary The address attempting to make a purchase.
     * @param _amount The amount of Wei being contributed.
     * @return True if the purchase is valid.
    */
    function _prevalidatePurchase(address _beneficiary, uint256 _amount) internal view returns(bool) {
        if(pool.state != 2) revert InvalidState(pool.state);
        if(block.timestamp < pool.options.start || block.timestamp > pool.options.end) revert NotInPurchasePeriod();
        if(pool.weiRaised + _amount > pool.options.hardCap) revert HardCapExceed();
        if(_amount < pool.options.min) revert PurchaseBelowMinimum();
        if(_amount + contributions[_beneficiary] > pool.options.max) revert PurchaseLimitExceed();
        return true;
    }

    /**
     * @param _options The presale options.
     * @return True if the pool configuration is valid.
    */
    function _prevalidatePool(PresaleOptions memory _options) internal view returns(bool) {
        if (_options.softCap == 0 || _options.softCap < _options.hardCap / 2) revert InvalidCapValue();
        if (_options.min == 0 || _options.min > _options.max) revert InvalidLimitValue();
        if (_options.liquidityBps < 5000 || _options.liquidityBps > 10000) revert InvalidLiquidityValue();
        if (_options.start > block.timestamp || _options.end < _options.start) revert InvalidTimestampValue();
        return true;
    }

    /**
     * @notice Tokens per user rate is dynamically calculated using the proportional allocation of current raise amount in Wei.
     * @param contributor The address of the contributor.
     * @return The amount of tokens claimable by the contributor.
    */
    function userTokens(address contributor) public view returns(uint256){
        return ((contributions[contributor] * SCALE) / pool.weiRaised * pool.tokensClaimable) / SCALE;
    }

    /**
     * @notice Calculates the amount of tokens allocated for liquidity.
     * @return The amount of tokens for liquidity.
    */
    function _tokensForLiquidity() internal view returns (uint256){
        return pool.options.tokenDeposit * pool.options.liquidityBps / 10_000;
    }

    /**
     * @notice Calculates the amount of tokens allocated for the presale.
     * @return The amount of tokens available for the presale.
    */
    function _tokensForPresale() internal view returns (uint256){
        return pool.options.tokenDeposit - (pool.options.tokenDeposit * pool.options.liquidityBps / 10_000);
    }

    /**
     * @notice Calculates the amount of W   ei allocated for liquidity provisioning.
     * @return The amount of Wei for liquidity provisioning.
    */
    function _weiForLiquidity() internal view returns (uint256){
        return pool.weiRaised * pool.options.liquidityBps / 10_000;
    }
}
