// SPDX-License-Identifier: MIT
// solhint-disable-next-line
pragma solidity ^0.8.23;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IUniswapV2Factory } from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import { IUniswapV2Router02 } from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import { PresaleMath } from "./helpers/PresaleMath.sol";

contract Presale is Ownable(msg.sender) {
    using PresaleMath for uint256;
    
    struct Data {
        uint256 presaleTokens;
        uint256 ethRaised;
        bytes32 status;
        bytes32 options;
        address creatorWallet;
        address weth;
        IERC20 token;
        IUniswapV2Factory UniswapV2Factory;
        IUniswapV2Router02 UniswapV2Router02;
        uint8 tokenDecimals;
    }

    struct Pool {
        uint256 saleRate;
        uint256 listingRate;
        uint256 hardCap;
        uint256 softCap;
        uint256 maxBuy;
        uint256 minBuy;
        uint96 startTime;
        uint96 endTime;
        uint8 liquidityPortion;
    }

    error PurchaseFail(string reason);

    event Purchased(
        address beneficiary, 
        uint256 contribution, 
        uint256 amount
    );

    mapping(address => uint256) public ethContribution;

    Data public data;
    Pool public pool;

    constructor (
        Data memory _data,
        Pool memory _pool
        )  {

    }

    receive() external payable{}

    function deposit() external onlyOwner {
        
    }

    function finalize() external onlyOwner {
        
    }

    function withdraw() external onlyOwner {
        
    }

    function cancel() external onlyOwner {
        
    }

    function claim() external {
        
    }

    function refund() external {
        
    }

    function purchase() public payable {
        uint256 amount = msg.value;
        _prevalidatePurchase(msg.sender, amount);
        data.ethRaised += amount;
        data.presaleTokens -= amount;
        ethContribution[msg.sender] += amount;
    }

    function _prevalidatePurchase(address _beneficiary, uint256 _amount) internal view returns(bool) {
        if(_amount == 0) revert PurchaseFail("Wei Amount is 0");
        if(_amount < pool.minBuy) revert PurchaseFail("Purchase below min buy");
        if(_amount + ethContribution[_beneficiary] > pool.maxBuy) revert PurchaseFail("Buy limit exceeded");
        if(data.ethRaised > pool.hardCap) revert PurchaseFail("Hard cap reached");
        return true;
    }
}