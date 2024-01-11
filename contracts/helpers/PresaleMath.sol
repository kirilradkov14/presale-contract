// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

library PresaleMath {
    // Calculates the number of user tokens
    function userTokens(
        uint256 amount, 
        uint256 saleRate, 
        uint8 tokenDecimals
    ) internal pure returns (uint256) {
        return amount * saleRate / (10 ** (36 - tokenDecimals));
    }

    // Calculates the ETH amount for liquidity
    function liquidityETH(uint256 totalRaised, uint256 liquidityPortion) internal pure returns (uint256) {
        return totalRaised * liquidityPortion / 100;
    }

    // Calculates the withdrawable ETH amount
    function withdrawableETH(uint256 totalRaised, uint256 liquidityPortion) internal pure returns (uint256) {
        return totalRaised - liquidityETH(totalRaised, liquidityPortion);
    }

    // Calculates the total token deposit
    function tokenDeposit(
        uint256 hardCap, 
        uint256 saleRate,
        uint256 liquidityRate,
        uint256 liquidityPortion, 
        uint8 tokenDecimals
    ) internal pure returns (uint256) {
        uint256 forSale = userTokens(hardCap, saleRate, tokenDecimals);
        uint256 forLiquidity = depositLiquidityTokens(hardCap, liquidityRate, liquidityPortion, tokenDecimals);
        return forSale + forLiquidity;
    }

    // Calculates the tokens for depositing into liquidity
    function depositLiquidityTokens(
        uint256 hardCap, 
        uint256 liquidityRate, 
        uint256 liquidityPortion, 
        uint8 tokenDecimals
    ) internal pure returns (uint256) {
        return userTokens(hardCap, liquidityRate * liquidityPortion / 100, tokenDecimals);
    }
}
