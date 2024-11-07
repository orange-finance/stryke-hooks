// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct TokenIdInfo {
    uint128 totalLiquidity;
    uint128 totalSupply;
    uint128 liquidityUsed;
    uint256 feeGrowthInside0LastX128;
    uint256 feeGrowthInside1LastX128;
    uint128 tokensOwed0;
    uint128 tokensOwed1;
    uint64 lastDonation;
    uint128 donatedLiquidity;
    address token0;
    address token1;
    uint24 fee;
    uint128 reservedLiquidity;
}

// TODO: Obtain liquidity to utilize from data. At the moment, this isn't feasible since the handler doesn't pass the liquidity to a hook.
struct PositionUseData {
    address app;
    uint256 ttl;
    bool isCall;
    address pool;
    int24 tickLower;
    int24 tickUpper;
}

interface IV2Handler {
    function tokenIds(uint256 tokenId) external view returns (TokenIdInfo memory);
}
