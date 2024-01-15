// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { IUniswapV2Factory } from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import { IUniswapV2Router02 } from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import { PresaleMath } from "./helpers/PresaleMath.sol";

contract Presale is Ownable(msg.sender) {
    using PresaleMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address payable;

    address immutable DEAD = 0x000000000000000000000000000000000000dEaD;

    struct Data {
        uint256 presaleTokens;
        uint256 raised;
        address weth;
        IERC20 token;
        IUniswapV2Factory UniswapV2Factory;
        IUniswapV2Router02 UniswapV2Router02;
        uint8 decimals;
        uint8 status;
        uint8 refundOptions;
    }

    struct Pool {
        uint256 saleRate;
        uint256 listingRate;
        uint256 hardCap;
        uint256 softCap;
        uint256 max;
        uint256 min;
        uint96 start;
        uint96 end;
        uint8 liquidity;
    }

    error PurchaseError(string reason);
    error TimeError();
    error DepositError();
    error FinalizationError();
    error CancelationError();
    error ClaimError();
    error WithdrawalError();
    error RefundError();

    modifier onTime(){
        if(block.timestamp < pool.start) revert TimeError();
        if(block.timestamp > pool.end) revert TimeError();
        _;
    }
    
    event Purchase(
        address indexed beneficiary, 
        uint256 contribution, 
        uint256 amount
    );
    event Refund(address indexed beneficiary, uint256 amount);
    event Deposit(address indexed creator, uint256 amount);
    event TokenClaim(address indexed beneficiary, uint256 amount);
    event Withdraw(address indexed beneficiary, uint256 amount);
    event Cancel(address indexed beneficiary, uint256 amount);
    event Finalized(address indexed creator, uint256 amount, uint256 time);

    mapping(address => uint256) public weiContribution;

    Data public data;
    Pool public pool;

    constructor (
        address _weth,
        address _token,
        address _uniswapv2Router, 
        address _uniswapv2Factory,
        uint8 _decimals,
        uint8 _refundOptions,
        Pool memory _pool
    )  {

        Pool memory newPool = _pool;
        data.weth = _weth;
        data.token = IERC20(_token);
        data.UniswapV2Factory = IUniswapV2Factory(_uniswapv2Factory);
        data.UniswapV2Router02 = IUniswapV2Router02(_uniswapv2Router);
        data.decimals = _decimals;
        data.refundOptions = _refundOptions;
        pool = newPool;
    }

    receive() external payable {
        _purchase(msg.sender, msg.value);
    }

    function deposit() external onlyOwner {
        if(data.status != 0) revert DepositError();

        uint256 amount = PresaleMath.tokenDeposit(
            pool.hardCap, 
            pool.saleRate, 
            pool.listingRate, 
            pool.liquidity, 
            data.decimals
        );

        data.status = 1;
        if(!data.token.transferFrom(msg.sender, address(this), amount)) revert DepositError();
        emit Deposit(msg.sender, amount);
    }

    function finalize() external onlyOwner {
        if(data.status != 1) revert FinalizationError();
        if(data.raised >= pool.softCap) revert FinalizationError();

        data.status = 3;

        _liquify();

        // Withdraw the ETH
        uint256 withdrawable = PresaleMath.withdrawableETH(data.raised, pool.liquidity);
        if (withdrawable > 0) {
            payable(msg.sender).sendValue(withdrawable);
        }

        // When hc not reach we either burn or refund the remaining tokens
        if(data.raised < pool.hardCap ) {
            uint256 remainder = PresaleMath.remainder(
                pool.hardCap, 
                data.raised, 
                pool.saleRate, 
                pool.listingRate, 
                pool.liquidity, 
                data.decimals
            );
            address target = data.refundOptions != 0 ? msg.sender : DEAD;

            if(!data.token.transfer(target, remainder)) {
                revert FinalizationError();
            }
        }

        emit Finalized(msg.sender, data.raised, block.timestamp);
    }

    function cancel() external onlyOwner {
        if(data.status > 2) revert CancelationError();

        data.status = 2;

        if (data.token.balanceOf(address(this)) > 0) {
            uint256 amount = PresaleMath.tokenDeposit(
                pool.hardCap,
                pool.saleRate,
                pool.listingRate,
                pool.liquidity,
                data.decimals
            );

            if(!data.token.transfer(msg.sender, amount)) revert WithdrawalError();

            emit Cancel(msg.sender, amount);
        }
    }
    
    function claim() external onTime {
        if(data.status != 3) revert ClaimError();

        uint256 amount = PresaleMath.userTokens(
            weiContribution[msg.sender], 
            pool.saleRate, 
            data.decimals
        );

        weiContribution[msg.sender] = 0;

        if(!data.token.transfer(msg.sender, amount)) revert ClaimError();
        emit TokenClaim(msg.sender, amount);
    }

    function refund() external {
        if (data.status == 2) revert RefundError();

        uint256 amount = weiContribution[msg.sender];
        if(amount == 0) revert ClaimError();

        if(address(this).balance >= amount) {
            weiContribution[msg.sender] = 0;
            payable(msg.sender).sendValue(amount);
            emit Refund(msg.sender, amount);
        }
    }

    function _purchase(address beneficiary, uint256 amount) private onTime {
        _prevalidatePurchase(beneficiary, amount);
        data.raised += amount;
        data.presaleTokens -= amount;
        weiContribution[beneficiary] += amount;

        emit Purchase(
            beneficiary, 
            PresaleMath.userTokens(amount, pool.saleRate, data.decimals), 
            amount
        );
    }

    function _liquify() internal {
        uint256 tokensForLiquidity = PresaleMath.liquidityTokens(
            data.raised, 
            pool.listingRate, 
            pool.liquidity, 
            data.decimals
        );
        uint256 liquidityEth = PresaleMath.liquidityETH(data.raised, pool.liquidity);

        (uint amountToken, uint amountETH, ) = data.UniswapV2Router02.addLiquidityETH{value : liquidityEth}(
            address(data.token),
            tokensForLiquidity, 
            tokensForLiquidity, 
            liquidityEth, 
            owner(), 
            block.timestamp + 600
        );

        if(amountToken != tokensForLiquidity && amountETH != liquidityEth) revert FinalizationError();
    }

    function _prevalidatePurchase(
        address _beneficiary, 
        uint256 _amount
    ) internal view returns(bool) {
        if(_amount == 0) revert PurchaseError("Amount is 0");
        if(_amount < pool.min) revert PurchaseError("Purchase below min");
        if(_amount + weiContribution[_beneficiary] > pool.max) revert PurchaseError("Buy limit exceeded");
        if(data.raised > pool.hardCap) revert PurchaseError("Hard cap reached");
        return true;
    }
}