// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/IERC4626.sol";
// import { ERC20 } from "@rari-capital/solmate/src/tokens/ERC20.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import { IERC4626 } from "./interfaces/IERC4626.sol";
import { SafeTransferLib } from "@rari-capital/solmate/src/utils/SafeTransferLib.sol";
import "./interfaces/IWETH9.sol";
import "./helpers/AaveHelperBase.sol";
import { AaveInterface, IAaveV3Oracle } from "./interfaces/aave/AaveInterface.sol";
import "./helpers/UniswapV3HelperBase.sol";
import {FlashLoanSimpleReceiverBase} from  "@aave/core-v3/contracts/flashloan/base/FlashLoanSimpleReceiverBase.sol";
import {IPoolAddressesProvider} from  "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";

contract SUSDEVault is FlashLoanSimpleReceiverBase, ERC20, IERC4626, ReentrancyGuard, AaveHelperBase, UniswapV3HelperBase{
    
    using SafeTransferLib for ERC20;

    address public immutable asset; // sUSDe
    IWETH9 immutable WETH9;
    address public governance;
    address public pendingGovernance;
    uint public slippage;
    uint24 public fee = 3000;

    event PendingGovernance(address indexed governance);
    event GovernanceAccepted(address indexed newGovernance);

    struct ActionInput{
        uint supplyAmount;
        uint flAmount;
        uint flAmountWithFee;
        uint slippagePercent;
    }

    enum VauitAction{
        Rebalance,
        WithdrawFromAave
    }

    /**
	 * @dev constructor
	 * @notice Intializes state variables of vault.
	 * @param _asset The address of the token to be supplied.
	 * @param _weth9 address of WETH9
	 */
    constructor(
        address _asset,
        address _addressProvider,
        address _weth9,
        uint _slippage
    ) ERC20("SUSDEVault", "sUSDeV") FlashLoanSimpleReceiverBase(IPoolAddressesProvider(_addressProvider)) {
        asset = _asset;
        governance = msg.sender;
        WETH9 = IWETH9(_weth9);
        slippage = _slippage;
    }

    modifier onlyGovernance{
        require(msg.sender == governance, "Only governance can execute.");
        _;
    }

    // swap WETH9 to Asset (sUSDe) on uniswap
    function swapWethToAsset(uint amount) private returns (uint) {
        // convert weth to usdt
        uniswapV3Swap(SellInfo(
            address(WETH9),
            address(0xdAC17F958D2ee523a2206206994597C13D831ec7),
            fee,
            0,
            amount
        ));

        // get total balance of usdt
        uint usdtBalance = ERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7).balanceOf(address(this));
        // convert usdt to asset(sUSDe)
        uint24 fee2 = 500;
        uint returnAmount = uniswapV3Swap(SellInfo(
            address(0xdAC17F958D2ee523a2206206994597C13D831ec7),
            asset,
            fee2,
            0,
            usdtBalance
        ));
        return returnAmount;
    }
        
    /**
    * @dev deposit
    * @notice user will deposite Eth using this function
    * @param assets The amount of the token to be supplied.
    * @param receiver address of share receiver
	 */
    function deposit(uint256 assets, address receiver) external override nonReentrant returns (uint256 shares) {
        require(assets > 0 , "assets must be greater than zero");
        require(receiver != address(0) && receiver != address(this), "receiver shouldn't be 0 address or this contract");        
        
        // Need to transfer before minting or ERC777s could reenter.
        bool _status = ERC20(asset).transferFrom(msg.sender, address(this), assets);
        require(_status == true, "sUSDe asset trasferFrom failed");

        require((shares = previewDeposit(assets)) != 0, "ZERO_SHARES");

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);
    }

    /**
	 * @dev withdraw
	 * @notice Withdraw function allows user to withdraw there eth amount by burning shares.
	 * @param shares input share amount
	 * @param receiver address of receiver
	 * @param owner address of owner of the shares
	 */
    function withdraw(
        uint256 shares,
        address receiver,
        address owner
    ) external nonReentrant override returns (uint256 assets) {
        require(receiver != address(0) && receiver != address(this), "receiver shouldn't be 0 address or this contract");
        require(msg.sender == owner, "only owner can execute.");

        // Check for rounding error since we round down in previewRedeem.
        require((assets = previewRedeem(shares)) != 0, "ZERO_ASSETS");

        _burn(owner, shares);

        // transfer the sUSDe to user
        ERC20(asset).transfer(receiver, assets);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);
    }

    function rebalance(uint supplyAmount, uint flAmount, uint flAmountWithFee, uint slippagePercent)private {
        AaveInterface aave = AaveInterface(aaveProvider.getPool());

        uint slippageAmt = calculateSlippageAmount(supplyAmount, slippagePercent);
        
        uint returnAmount = swapWethToAsset(flAmount);

        supplyAmount += returnAmount;
        // call supply
        ERC20(asset).approve(address(aave), supplyAmount);
        aave.supply(asset, supplyAmount, address(this), 0);

        aave.borrow(address(WETH9), flAmountWithFee, 2, 0, address(this));
    }

    function withdrawFromAave(uint withdrawAmount, uint flAmount, uint flAmountWithFee, uint slippagePercent)private {
        AaveInterface aave = AaveInterface(aaveProvider.getPool());
        // call aave repay
        WETH9.approve(address(aave), flAmount);
        aave.repay(address(WETH9), flAmount, 2, address(this));
        
        aave.withdraw(asset, withdrawAmount, address(this));

    }

    function executeOperation(
        address assetaddr,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external override returns (bool) {
        require(address(this) == initiator, "Untrusted loan initiator");
        AaveInterface aave = AaveInterface(aaveProvider.getPool());
        require(msg.sender == address(aave), "only pool");

        uint amountOwing = amount + premium;
        (VauitAction _action, bytes memory _actionParam) = abi.decode(params, (VauitAction, bytes));
        ActionInput memory _actionInput = abi.decode(_actionParam, (ActionInput));
        _actionInput.flAmountWithFee = amountOwing;

        if(_action == VauitAction.Rebalance){  
            rebalance(_actionInput.supplyAmount, _actionInput.flAmount, _actionInput.flAmountWithFee, _actionInput.slippagePercent);
        } else if(_action == VauitAction.WithdrawFromAave){
            withdrawFromAave(_actionInput.supplyAmount, _actionInput.flAmount, _actionInput.flAmountWithFee, _actionInput.slippagePercent);
        }

        IERC20(assetaddr).approve(address(aave), amountOwing);
        
        // repay Aave
        return true;
    }

    // /**
	//  * @dev callVaultAction
	//  * @notice callVaultAction function triggers aave flashloan in order to perform any opration like open position, Close position, deleverage, leverage.
	//  * @param operation operation from enum operation
	//  * @param amount amount
	//  * @param _data1 data require for swap (dev : data is received from 1inch api by calling it offchain).
	//  * @param _receiver receiver
	//  */
    function callVaultAction(address assetAddr, uint flashLoanAmount, bytes calldata param)external onlyGovernance{

        AaveInterface(aaveProvider.getPool()).flashLoanSimple(
            address(this),
            assetAddr,
            flashLoanAmount,
            param,
            0
        );
    }

    
    /**
     * @dev Calculates the slippage amount given asset amount and slippage percentage.
     * @param assetAmount The asset amount with 18 decimal places.
     * @param slippagePercentage The slippage percentage in scaled format (1% = 10000).
     * @return slippageAmount The calculated slippage amount.
     */
    function calculateSlippageAmount(uint256 assetAmount, uint256 slippagePercentage) public pure returns (uint256) {
        require(slippagePercentage <= 100 * 10000, "Slippage percentage is too high"); // Ensure slippage percentage is within 100%
        
        // Calculate slippage amount: (assetAmount * slippagePercentage) / (100 * 10000)
        uint256 slippageAmount = (assetAmount * slippagePercentage) / (100 * 10000);
        
        return slippageAmount;
    }

    
    function totalAssets() public view override returns (uint256){
        uint amount = getVaultsActualBalance();
        
        (uint price, uint decimals) = getAssetPriceFromAave(asset);

        uint totalAsset = (amount * decimals) / price;
        // amount = amount + ERC20(asset).balanceOf(address(this));
        return totalAsset;
    }

    /**
     * @notice  Internal conversion function (from assets to shares)
     */
    function convertToShares(uint256 assets) public view returns (uint256) {
        uint256 supply = totalSupply(); // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? assets : ((assets * supply) / totalAssets() ) ;
    }

    /**
     * @notice  Internal conversion function (from shares to assets)
    */
    function convertToAssets(uint256 shares) public view returns (uint256) {
        uint256 supply = totalSupply(); // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? shares : ((shares * totalAssets()) / supply);
    }

    /**
     * @notice  This function gives amount of supply token and borrow token required to remove in order to remove input assets amount from aave position by keeping the leverage same.
     */
    function convertToSupply(uint256 assets) public view returns (uint256 supplyAmount, uint256 borrowAmount) {
        uint256 amount = getVaultsActualBalance();
        uint supplyBal = getCollateralAssetBalance();
        uint borrowBal = getDebtAssetBalance();

        supplyAmount = assets == amount ? supplyBal : ((supplyBal * assets) / amount);

        borrowAmount = assets == amount ? borrowBal : ((borrowBal * assets) / amount);
    }

    function previewDeposit(uint256 assets) public view override returns (uint256) {
        return convertToShares(assets);
    }

    function previewRedeem(uint256 shares) public view override returns (uint256) {
        return convertToAssets(shares);
    }

    function maxDeposit(address) external pure override returns (uint256) {
        return type(uint256).max;
    }

    function maxMint(address) external pure override returns (uint256) {
        return type(uint256).max;
    }

    function maxWithdraw(address owner) external view override returns (uint256) {
        return convertToAssets(balanceOf(owner));
    }

    function maxRedeem(address owner) external view override returns (uint256) {
        return balanceOf(owner);
    }

    function getVaultsActualBalance() public view returns(uint amount){
        uint supplyBal = getCollateralAssetBalance();
        uint borrowBal = getDebtAssetBalance();
        amount = supplyBal - borrowBal;
    }

    /**
     * @notice `setGovernance()` should be called by the existing governance address prior to calling this function.
     */
    function setGovernance(address _governance) external onlyGovernance {
        require(_governance != address(0), "Zero Address");
        pendingGovernance = _governance;
        emit PendingGovernance(pendingGovernance);
    }

    /**
     * @notice Governance address is not updated until the new governance
     * address has called `acceptGovernance()` to accept this responsibility.
     */
    function acceptGovernance() external {
        require(msg.sender == pendingGovernance, "pendingGovernance");
        governance = msg.sender;
        emit GovernanceAccepted(governance);
    }

    function getAssetPriceFromAave(address asset)private view returns(uint price, uint decimals){
        address priceOracleAddress = aaveProvider.getPriceOracle();
        price = IAaveV3Oracle(priceOracleAddress).getAssetPrice(asset);
        decimals = IAaveV3Oracle(priceOracleAddress).BASE_CURRENCY_UNIT();
    }

    function getCollateralAssetBalance()public view returns(uint){ //usd
        (uint price, uint decimals) = getAssetPriceFromAave(asset);
        uint SupplyBalance = aTokenSupply.balanceOf(address(this));
        uint idleBalance = ERC20(asset).balanceOf(address(this));
        uint totalBal = idleBalance + SupplyBalance;
        if(totalBal <= 0) return 0;

        uint balanceUSD = (totalBal * price) / decimals;
        return balanceUSD;
    }

    function getDebtAssetBalance()public view returns(uint){
        (uint price, uint decimals) = getAssetPriceFromAave(address(WETH9));
        uint SupplyBalance = dTokenDebt.balanceOf(address(this));
        if(SupplyBalance <= 0) return 0;

        uint balanceUSD = (SupplyBalance * price) / decimals;
        return balanceUSD;
    }

    
    receive() external payable {}
}
