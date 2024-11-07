// SPDX-License-Identifier: MIT

pragma solidity 0.8.27;

import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {LiquidityAmounts} from "@uniswap/v3-periphery/contracts/libraries/LiquidityAmounts.sol";
import {TickMath} from "@uniswap/v3-core/contracts/libraries/TickMath.sol";

library UniswapV3Library {
    using TickMath for int24;

    function currentTick(IUniswapV3Pool pool) internal view returns (int24 value) {
        (, value, , , , , ) = pool.slot0();
    }

    function currentTick(address pool) internal view returns (int24 value) {
        return currentTick(IUniswapV3Pool(pool));
    }

    function sqrtPriceX96(IUniswapV3Pool pool) internal view returns (uint160 value) {
        (value, , , , , , ) = pool.slot0();
    }

    function sqrtPriceX96(address pool) internal view returns (uint160 value) {
        return sqrtPriceX96(IUniswapV3Pool(pool));
    }

    function getAmountsForLiquidity(
        IUniswapV3Pool pool,
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity
    ) internal view returns (uint256 amount0, uint256 amount1) {
        return
            LiquidityAmounts.getAmountsForLiquidity(
                sqrtPriceX96(pool),
                tickLower.getSqrtRatioAtTick(),
                tickUpper.getSqrtRatioAtTick(),
                liquidity
            );
    }

    function getAmountsForLiquidity(
        address pool,
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity
    ) internal view returns (uint256 amount0, uint256 amount1) {
        return getAmountsForLiquidity(IUniswapV3Pool(pool), tickLower, tickUpper, liquidity);
    }

    function getLiquidityForAmounts(
        IUniswapV3Pool pool,
        int24 tickLower,
        int24 tickUpper,
        uint256 amount0,
        uint256 amount1
    ) internal view returns (uint128 liquidity) {
        return
            LiquidityAmounts.getLiquidityForAmounts(
                sqrtPriceX96(pool),
                tickLower.getSqrtRatioAtTick(),
                tickUpper.getSqrtRatioAtTick(),
                amount0,
                amount1
            );
    }

    function getLiquidityForAmounts(
        address pool,
        int24 tickLower,
        int24 tickUpper,
        uint256 amount0,
        uint256 amount1
    ) internal view returns (uint128 liquidity) {
        return getLiquidityForAmounts(IUniswapV3Pool(pool), tickLower, tickUpper, amount0, amount1);
    }
}
