// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

library PresaleMath {
    uint256 constant SCALE = 10**18;

    // Calculate the tokens per user
    function userTokens(
        uint256 weiContribution,
        uint256 saleRate
    ) internal pure returns (uint256) {
        return weiContribution * saleRate;
    }

    // Calculate wei required for providing liquidity
    function liquidityWei(
        uint256 weiRaised,
        uint8 liquidityPortion
    ) internal pure returns (uint256) {
        return weiRaised * liquidityPortion / 100;
    }

    // Calculates the amount the owner is eligible to withdraw on finalization
    function withdrawableWei(
        uint256 weiRaised,
        uint8 liquidityPortion
    ) internal pure returns (uint256) {
        return weiRaised - liquidityWei(weiRaised, liquidityPortion);
    }

    function totalTokens(
        uint256 amount,
        uint256 saleRate,
        uint256 listingRate
    ) internal pure returns (uint256) {
        return amount * saleRate + amount * listingRate;
    }

    function calculateTokens(
        uint256 amount,
        uint256 rate
    ) internal pure returns (uint256) {
        return amount * rate;
    }

    // Calculate remainder: total tokens deposited - current raise
    function remainder(
        uint256 amountTotal,
        uint256 amountRaised,
        uint256 saleRate,
        uint256 listingRate
    ) internal pure returns (uint256) {
        uint256 _total = amountTotal * saleRate + amountTotal * listingRate;
        uint256 _raised = amountRaised * saleRate + amountRaised * listingRate;
        return _total - _raised;
    }

}