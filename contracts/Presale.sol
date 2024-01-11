// SPDX-License-Identifier: MIT
// solhint-disable-next-line
pragma solidity ^0.8.23;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IUniswapV2Factory } from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import { IUniswapV2Router02 } from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract Presale is Ownable(msg.sender) {

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
        Pool pool;
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

    mapping(address => uint256) public ethContribution;

    constructor (
        Data memory _data,
        Pool memory _pool
        )  {

        }
}