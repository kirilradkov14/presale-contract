// SPDX-License-Identifier: UNLICENSED
// solhint-disable-next-line
pragma solidity ^0.8.19;

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}
