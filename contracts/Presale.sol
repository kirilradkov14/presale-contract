// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { IUniswapV2Factory } from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import { IUniswapV2Router02 } from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import { PresaleMath } from "./libraries/PresaleMath.sol";

contract Presale is Ownable(msg.sender) {
    using PresaleMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address payable;

    address immutable DEAD = 0x000000000000000000000000000000000000dEaD;

    struct Data {
        uint256 presaleTokens;
        uint256 raised;
        address weth;
        IUniswapV2Factory UniswapV2Factory;
        IUniswapV2Router02 UniswapV2Router02;
        uint8 state;
    }

    struct Pool {
        IERC20 token;
        uint256 saleRate;
        uint256 listingRate;
        uint256 hardCap;
        uint256 softCap;
        uint256 max;
        uint256 min;
        uint96 start;
        uint96 end;
        uint8 liquidity;
        uint8 refundOptions;
    }
    
    error Validation(string reason);
    error Forbidden(string reason);
    error Insufficient(string reason);

    modifier finalizable(){
        if(data.raised < pool.softCap) revert Forbidden("");
        if(pool.hardCap < data.raised && block.timestamp > pool.end) revert Forbidden("");
        _;
    }

    event Purchase(
        address indexed beneficiary, 
        uint256 contribution, 
        uint256 amount
    );

    event Finalized(
        address indexed creator, 
        uint256 amount, 
        uint256 timestamp
    );

    event Refund(
        address indexed beneficiary, 
        uint256 amount, 
        uint256 timestamp
    );

    event Deposit(
        address indexed creator,
        uint256 amount, 
        uint256 timestamp
    );

    event TokenClaim(
        address indexed beneficiary, 
        uint256 amount, 
        uint256 timestamp
    );

    event Withdraw(
        address indexed beneficiary, 
        uint256 amount, 
        uint256 timestamp
    );

    event Cancel(address indexed creator, uint256 timestamp);

    mapping(address => uint256) public weiContribution;

    Data public data;
    Pool public pool;
    
    constructor (
        address _weth,
        address _uniswapv2Router, 
        address _uniswapv2Factory
    )  {
        if(_weth == address(0)) revert Validation("");
        if(_uniswapv2Router == address(0)) revert Validation("");
        if(_uniswapv2Factory == address(0)) revert Validation("");

        data.weth = _weth;
        data.UniswapV2Factory = IUniswapV2Factory(_uniswapv2Factory);
        data.UniswapV2Router02 = IUniswapV2Router02(_uniswapv2Router);

        // @dev would return the pair
        // data.UniswapV2Factory.getPair(address(pool.token), data.weth);
    }

    receive() external payable {
        _purchase(msg.sender, msg.value);
    }

    function createPresale(
        Pool memory _pool
    ) external onlyOwner returns (address) {
        if(data.state != 0) revert Forbidden("");

        _prevalidatePool(_pool);

        data.state = 1;
        pool = _pool;

        return address(this);
    }

    function deposit() external onlyOwner returns (uint256) {
        if(data.state != 1) revert Forbidden("");

        uint256 amount = PresaleMath.totalTokens(
            pool.hardCap,
            pool.saleRate,
            pool.listingRate
        );

        data.state = 2;

        pool.token.safeTransferFrom(msg.sender, address(this), amount);

        emit Deposit(
            msg.sender,
            amount,
            block.timestamp
        );

        return amount;
    }

    function finalize() external onlyOwner finalizable returns(bool) {
        if(data.state != 2) revert Forbidden("");

        data.state = 4;

        _liquify();

        // Withdraw the wei
        uint256 withdrawable = PresaleMath.withdrawableWei(data.raised, pool.liquidity);
        if (withdrawable > 0) {
            payable(msg.sender).sendValue(withdrawable);
        }

        // When hc not reach we either burn or refund the remaining tokens
        if(data.raised < pool.hardCap ) {
            uint256 remainder = PresaleMath.remainder(
                pool.hardCap,
                data.raised,
                pool.saleRate,
                pool.listingRate
            );
            address target = pool.refundOptions != 0 ? msg.sender : DEAD;

            pool.token.safeTransfer(target, remainder);
        }

        emit Finalized(
            msg.sender, 
            data.raised, 
            block.timestamp
        );
        
        return true;
    }

    function cancel() external onlyOwner returns(bool){
        if(data.state > 3) revert Forbidden("");

        data.state = 3;

        if (pool.token.balanceOf(address(this)) > 0) {
            uint256 amount = data.presaleTokens;
            data.presaleTokens = 0;
            pool.token.safeTransfer(msg.sender, amount);
        }

        emit Cancel(msg.sender, block.timestamp);

        return true;
    }
    
    function claim() external returns (uint256) {
        if(data.state != 4) revert Forbidden("");

        uint256 amount = PresaleMath.userTokens(
            weiContribution[msg.sender],
            pool.saleRate
        );

        weiContribution[msg.sender] = 0;

        pool.token.safeTransfer(msg.sender, amount);
        
        emit TokenClaim(
            msg.sender, 
            amount, 
            block.timestamp
        );

        return amount;
    }

    function refund() external returns (uint256) {
        if (data.state == 3) revert Forbidden("");

        uint256 amount = weiContribution[msg.sender];
        if(amount == 0) revert Insufficient("");

        if(address(this).balance >= amount) {
            weiContribution[msg.sender] = 0;
            payable(msg.sender).sendValue(amount);
            emit Refund(
                msg.sender, 
                amount, 
                block.timestamp
            );
        }

        return amount;
    }

    function _purchase(address beneficiary, uint256 amount) private {
        _prevalidatePurchase(beneficiary, amount);
        data.raised += amount;
        data.presaleTokens -= amount;
        weiContribution[beneficiary] += amount;

        emit Purchase(
            beneficiary, 
            PresaleMath.userTokens(amount, pool.saleRate), 
            amount
        );
    }

    function _liquify() internal {
        uint256 _tokensForLiquidity = PresaleMath.calculateTokens(data.raised, pool.listingRate);
        uint256 _liquidityWei = PresaleMath.liquidityWei(data.raised, pool.liquidity);

        (uint amountToken, uint amountETH, ) = data.UniswapV2Router02.addLiquidityETH{value : _liquidityWei}(
            address(pool.token),
            _tokensForLiquidity, 
            _tokensForLiquidity, 
            _liquidityWei, 
            owner(), 
            block.timestamp + 600
        );

        if(amountToken != _tokensForLiquidity && amountETH != _liquidityWei) revert Insufficient("");
    }

    function _prevalidatePurchase(address _beneficiary, uint256 _amount) internal view returns(bool) {
        if(data.raised + _amount >= pool.hardCap) revert Validation("");
        if(block.timestamp < pool.start) revert Validation("");
        if(block.timestamp > pool.end) revert Validation("");
        if(_amount == 0) revert Validation("");
        if(_amount < pool.min) revert Validation("");
        if(_amount + weiContribution[_beneficiary] > pool.max) revert Validation("");
        return true;
    }

    function _prevalidatePool(Pool memory _pool) internal view returns(bool) {
        if (_pool.softCap == 0) revert Validation("");
        if (_pool.softCap < _pool.hardCap / 2) revert Validation("");
        if (_pool.saleRate == 0) revert Validation("");
        if (_pool.listingRate == 0) revert Validation("");
        if (_pool.min == 0) revert Validation("");
        if (_pool.min > _pool.max) revert Validation("");
        if (_pool.liquidity < 50 || _pool.liquidity > 100) revert Validation("");
        if (_pool.start > block.timestamp) revert Validation("");
        if (_pool.start > _pool.end) revert Validation("");
        if(address(_pool.token) == address(0)) revert Validation("");
        return true;
    }
}