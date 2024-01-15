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
        uint256 listingRate,
        uint256 liquidityPortion, 
        uint8 tokenDecimals
    ) internal pure returns (uint256) {
        uint256 forSale = userTokens(hardCap, saleRate, tokenDecimals);
        uint256 forLiquidity = depositLiquidityTokens(hardCap, listingRate, liquidityPortion, tokenDecimals);
        return forSale + forLiquidity;
    }

    // Calculates the tokens for depositing into liquidity
    function depositLiquidityTokens(
        uint256 hardCap, 
        uint256 listingRate, 
        uint256 liquidityPortion, 
        uint8 tokenDecimals
    ) internal pure returns (uint256) {
        return userTokens(hardCap, listingRate * liquidityPortion / 100, tokenDecimals);
    }


    function liquidityTokens(
        uint256 weiRaised, 
        uint256 listingRate, 
        uint256 liquidityPortion, 
        uint8 tokenDecimals
    ) internal pure returns (uint256) {
        uint256 tokensForLiquidity = weiRaised * listingRate * liquidityPortion / 100;
        return tokensForLiquidity / (10 ** (36 - tokenDecimals));
    }

    function remainder(
        uint256 hardCap,
        uint256 raised,
        uint256 saleRate,
        uint256 listingRate,
        uint256 liquidityPortion,
        uint8 tokenDecimals
    ) internal pure returns (uint256) {
        uint256 forDeposit = tokenDeposit(hardCap, saleRate, listingRate, liquidityPortion, tokenDecimals);
        uint256 forSale = userTokens(hardCap, saleRate, tokenDecimals);
        uint256 forLiquidity = liquidityTokens(raised, listingRate, liquidityPortion, tokenDecimals);

        return forDeposit - (forSale + forLiquidity);
    }
}
