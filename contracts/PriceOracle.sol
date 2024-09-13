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
        address pool,
        address token0,
        address token1
    ) public view returns (uint256 price0, uint256 price1) {
        (uint160 sqrtPriceX96, , , , , , ) = IUniswapV3Pool(pool).slot0();

        // Get the decimals for both tokens
        uint8 decimals0 = IERC20(token0).decimals();
        uint8 decimals1 = IERC20(token1).decimals();

        // Price of token0 in terms of token1
        price0 = (uint256(sqrtPriceX96) * uint256(sqrtPriceX96)) / (2 ** 192);

        // price1 = (1 << 192) * 1e18 / (uint256(sqrtPriceX96) * uint256(sqrtPriceX96));

        if (price0 != 0) {
            if (decimals0 > decimals1) {
                // price1 = (1 << 192) * (10 ** (decimals0 - decimals1)) / (uint256(sqrtPriceX96) * uint256(sqrtPriceX96));
                price1 = (1e18 / price0) * (10 ** (decimals0 - decimals1));
            }
            if (decimals1 > decimals0) {
                // price1 = (1 << 192) * (10 ** (decimals1 - decimals0)) / (uint256(sqrtPriceX96) * uint256(sqrtPriceX96));
                price1 = (1e18 / price0) * (10 ** (decimals1 - decimals0));
            }
            if (decimals0 == decimals1) {
                // price1 = (1 << 192) * 1e18 / (uint256(sqrtPriceX96) * uint256(sqrtPriceX96));
                price1 = (1e18 / price0) * (10 ** (decimals1 - decimals0));
            }
        } else  price1 = (1 << 192) * 1e18 / (uint256(sqrtPriceX96) * uint256(sqrtPriceX96));

    }
}
