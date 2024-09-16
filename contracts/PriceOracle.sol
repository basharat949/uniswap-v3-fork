// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-periphery/contracts/libraries/OracleLibrary.sol";
import "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import "./interface/IERC20.sol";

contract PriceOracle {
    function getAveragePrice(
        address pool,
        uint32 secondsAgo,
        uint256 _amountIn,
        address _tokenIn,
        address _tokenOut
    ) external view returns (uint256 price, uint256 quoteAmount) {
        // Call the consult function from OracleLibrary
        (int24 arithmeticMeanTick, ) = OracleLibrary.consult(pool, secondsAgo);

        // Convert the tick to a price using the TickMath library
        uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(arithmeticMeanTick);


        // Calculate the price using the sqrtPriceX96 value
        price = (uint256(sqrtPriceX96) * uint256(sqrtPriceX96)) / (2 ** 192);

        quoteAmount = OracleLibrary.getQuoteAtTick(
            arithmeticMeanTick,
            uint128(_amountIn),
            _tokenIn,
            _tokenOut
        );

    }

    function getPrices(
        address pool

    ) public view returns (uint256 price0, uint256 price1) {
        (uint160 sqrtPriceX96, , , , , , ) = IUniswapV3Pool(pool).slot0();
        // uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(tick);
        
        address token0 = IUniswapV3Pool(pool).token0();
        address token1 = IUniswapV3Pool(pool).token1();

        // Get the decimals for both tokens
        uint8 decimals0 = IERC20(token0).decimals();
        uint8 decimals1 = IERC20(token1).decimals();

        uint256 baseAmountToken0 = 10 ** decimals0;
        uint256 baseAmountToken1 = 10 ** decimals1;


        if (sqrtPriceX96 <= type(uint128).max) {
            uint256 ratioX192 = uint256(sqrtPriceX96) * sqrtPriceX96;
            // Price of token0 in terms of token1
            price0 = FullMath.mulDiv(ratioX192, baseAmountToken0, 1 << 192);
            // Price of token1 in terms of token0
            price1 = FullMath.mulDiv(1 << 192, baseAmountToken1, ratioX192);
        } else {
            uint256 ratioX128 = FullMath.mulDiv(sqrtPriceX96, sqrtPriceX96, 1 << 64);
            // Price of token0 in terms of token1
            price0 = FullMath.mulDiv(ratioX128, baseAmountToken0, 1 << 128);
            // Price of token1 in terms of token0
            price1 = FullMath.mulDiv(1 << 128, baseAmountToken1, ratioX128);
        }

        price1 = decimals0 >= decimals1 ? price1 * (10 ** (decimals0 - decimals1)) : price1 * (10 ** (decimals1 - decimals0));
    }
}
