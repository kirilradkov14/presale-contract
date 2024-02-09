// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

/** 
 @author Kiril Radkov
 @title PresaleMath
 @notice Provides utility functions for presale calculations.
 */
library PresaleMath {

    /**
     * @notice Calculates the number of tokens a user gets for their contribution.
     * @param weiContribution The amount of Wei contributed by the user.
     * @param saleRate The rate at which tokens are sold per Wei.
     * @return The number of tokens to be received by the user.
     */
    function userTokens(uint256 weiContribution, uint256 saleRate) internal pure returns (uint256) {
        return weiContribution * saleRate;
    }
    
    /**
     * @notice Calculates the amount of Wei to be allocated for liquidity based on a percentage.
     * @param weiRaised The total amount of Wei raised in the presale.
     * @param liquidityPortion The percentage of the raised amount to be allocated for liquidity.
     * @return The amount of Wei to be allocated for liquidity.
     */
    function liquidityWei(uint256 weiRaised, uint8 liquidityPortion) internal pure returns (uint256) {
        return (weiRaised * liquidityPortion) / 100;
    }

    /**
     * @notice Calculates the amount of Wei that can be withdrawn by the owner after the presale.
     * @param weiRaised The total amount of Wei raised in the presale.
     * @param liquidityPortion The percentage of the raised amount to be allocated for liquidity.
     * @return The amount of Wei that can be withdrawn.
     */
    function withdrawableWei(uint256 weiRaised, uint8 liquidityPortion) internal pure returns (uint256) {
        return weiRaised - liquidityWei(weiRaised, liquidityPortion);
    }

    /**
     * @notice Calculates the total number of tokens required for the sale and listing.
     * @param amount The amount of Wei raised.
     * @param saleRate The rate at which tokens are sold per Wei.
     * @param listingRate The rate at which tokens are listed per Wei.
     * @param liquidityPortion The percentage of the raised amount to be allocated for liquidity.
     * @return The total number of tokens required.
     */
    function totalTokens(
        uint256 amount, 
        uint256 saleRate, 
        uint256 listingRate, 
        uint8 liquidityPortion
    ) internal pure returns (uint256) {
        uint256 forLiquidity = amount * listingRate * liquidityPortion / 100;
        return amount * saleRate - forLiquidity;
    }

    /**
     * @notice Calculates the number of tokens for a given amount at a specific rate.
     * @param amount The amount of Wei or tokens.
     * @param rate The rate at which to calculate the tokens.
     * @return The calculated number of tokens.
     */
    function calculateTokens(uint256 amount, uint256 rate) internal pure returns (uint256) {
        return amount * rate;
    }

    /**
     * @notice Calculates the remaining number of tokens after the sale.
     * @param totalAmount The total amount for which tokens are available.
     * @param raisedAmount The amount raised in the presale.
     * @param saleRate The rate at which tokens were sold per Wei.
     * @param listingRate The rate at which tokens were listed per Wei.
     * @param liquidityPortion The percentage of the raised amount to be allocated for liquidity.
     * @return The number of unsold tokens.
     */
    function remainder(
        uint256 totalAmount, 
        uint256 raisedAmount, 
        uint256 saleRate, 
        uint256 listingRate, 
        uint8 liquidityPortion
    ) internal pure returns (uint256) {
        uint256 _totalTokens = totalTokens(
            totalAmount, 
            saleRate, 
            listingRate, 
            liquidityPortion
        );
        uint256 _soldTokens = totalTokens(
            raisedAmount, 
            saleRate, 
            listingRate, 
            liquidityPortion
        );

        return _totalTokens - _soldTokens;
    }
}
