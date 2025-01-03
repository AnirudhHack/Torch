//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "../interfaces/UniswapV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract UniswapV3HelperBase {
    using SafeERC20 for IERC20;
	/**
	 * @dev uniswap v3 Swap Router
	 */
	ISwapRouter02 constant swapRouter =
		ISwapRouter02(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45);


	struct SellInfo {
		address sellAddr; //token to be sold
		address buyAddr; //token to be bought
		uint24 fee; //pool fees for buyAddr-sellAddr token pair
		uint256 slippageAmt; //slippage.
		uint256 sellAmt; //amount of token to be bought
	}

	/**
	 * @dev Swap Function
	 * @notice Swap token(sellAddr) with token(buyAddr), to get max buy tokens
	 * @param sellData Data input for the sell action
	 */
	function uniswapV3Swap(
		SellInfo memory sellData
	) internal returns(uint) {

		IERC20(sellData.sellAddr).forceApprove(
				address(swapRouter), 
				sellData.sellAmt
		);

		ExactInputSingleParams memory params = ExactInputSingleParams({
			tokenIn: sellData.sellAddr,
			tokenOut: sellData.buyAddr,
			fee: sellData.fee,
			recipient: address(this),
			amountIn: sellData.sellAmt,
			amountOutMinimum: sellData.slippageAmt, 
			sqrtPriceLimitX96: 0
		});
		
		uint256 _buyAmt = swapRouter.exactInputSingle(params);
		require(sellData.slippageAmt <= _buyAmt, "slippage hit");
		return _buyAmt;
	}
}