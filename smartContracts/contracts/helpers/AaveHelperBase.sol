//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { AavePoolProviderInterface, AaveDataProviderInterface, IAToken, IDToken } from "../interfaces/aave/AaveInterface.sol";

abstract contract AaveHelperBase {
	/**
	 * @dev Aave Pool Provider
    */
	AavePoolProviderInterface internal constant aaveProvider =
		AavePoolProviderInterface(0x2f39d218133AFaB8F2B819B1066c7E434Ad94E9e);
		
	AaveDataProviderInterface internal constant aaveData =
		AaveDataProviderInterface(0x41393e5e337606dc3821075Af65AeE84D7688CBD);

	IAToken internal constant aTokenSupply = IAToken(0x4579a27aF00A62C0EB156349f31B345c08386419); // Aave Ethereum sUSDe (aEthsUSDe)

	IDToken internal constant dTokenDebt = IDToken(0xeA51d7853EEFb32b6ee06b1C12E6dcCA88Be0fFE);  // Aave Ethereum Variable Debt WETH (variableDebtEthWETH)

	/**
	 * @dev Get total collateral balance for an asset
	 * @param token token address of the collateral.
	 */
    function getCollateralBalance(address token)
		internal
		view
		returns (uint256 bal)
	{
		(bal, , , , , , , , ) = aaveData.getUserReserveData(
			token,
			address(this)
		);
	}

	/**
	 * @dev Get debt token address for an asset
	 * @param token token address of the asset
	 * @param rateMode Debt type: stable-1, variable-2
	 */
	function getDTokenAddr(address token, uint256 rateMode)
		internal
		view
		returns(address dToken)
	{
		if (rateMode == 1) {
			(, dToken, ) = aaveData.getReserveTokensAddresses(token);
		} else {
			(, , dToken) = aaveData.getReserveTokensAddresses(token);
		}
	}
}