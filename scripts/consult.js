const { ethers } = require("hardhat");

async function main() {

    const poolAddress = "0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640"; // USDC/ETH

    // Deploy the PriceOracle contract
    const PriceOracle = await ethers.getContractFactory("PriceOracle");
    const priceOracle = await PriceOracle.deploy();

    console.log("PriceOracle deployed to:", priceOracle.target);

    // Call the consult function to get the price
    const secondsAgo = 1;
    const amountIn = ethers.parseUnits("1");
    const tokenIn = '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48'
    const tokenOut = '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2'
    const {price, quoteAmount} = await priceOracle.getAveragePrice(poolAddress, secondsAgo, amountIn,tokenIn,tokenOut);
    console.log(`Price from ${secondsAgo} seconds ago:`, price.toString(), "Quote amount is:", quoteAmount.toString());

    const {price0, price1} = await priceOracle.getPrices(poolAddress, tokenIn, tokenOut);

    console.log("Price0 :", price0.toString(), "Price1 is:", price1.toString());
}



main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
