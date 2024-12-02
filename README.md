# Torch

![image](https://github.com/user-attachments/assets/defa7066-c52a-4742-ba97-a6d935ae1d6a)

Torch is a protocol that amplifies sUSDe yields through intelligent leverage strategies (recursive borrowing strategy), turning the base 29% APY into up to 81% APY. Torch currently has 1 sUSDe vault deployed on eth forknet. Built specifically for the Ethena ecosystem and sUSDe holders, Torch represents the next evolution in yield optimization for Internet Money.


## 🏆 Hackathon Tracks inegration

The project is eligible for following track as it increases the ethena's sUSDe holders apy from 29 % to 81 % using recursive borrowing strategy. 
1. **Most Innovative Use of sUSDe Rewards** 

2. **Best Overall Application** 

Here is the sUSDe integration (below integration shows that a sUSDe vault is built that increases sUSDe position APY)
SO below is the vault implementation:
https://github.com/AnirudhHack/Torch/blob/e73dbb0e9f099a828738aeb5e4ad672c73eaa9eb/smartContracts/contracts/Vault.sol#L17
  ```solidity
  // Vault.sol
  contract SUSDEVault is IERC4626 {
      address public immutable asset; // sUSDe
      // Amplifies sUSDe yield from 29% to 81.62% APY
  }
  ```

Here the underly asset in vault is sUSDe:
https://github.com/AnirudhHack/Torch/blob/e73dbb0e9f099a828738aeb5e4ad672c73eaa9eb/smartContracts/contracts/Vault.sol#L21
https://github.com/AnirudhHack/Torch/blob/c98060ec044837887abc86ead021a600ff20ea2b/smartContracts/test/Lock.js#L15



## vault Deposit and withdraw page:
![image](https://github.com/user-attachments/assets/73a78220-6740-4f5c-b89a-ac5ddb887015)

## Dapp Deployment link
https://torch-dapp.vercel.app/

## Video Demo
https://drive.google.com/file/d/1ES5or3WSMR4jhV_tbXidfCRf7XLWBPkR/view?usp=sharing

## Vault Strategy
This vault implements a recursive borrowing strategy to amplify your sUSDe yields through Aave. Here is how it works:
1. Your sUSDe is supplied to Aave as collateral
2. We borrow WETH against your sUSDe position (up to the optimal LTV)
3. The borrowed WETH is swapped back to sUSDe
4. The new sUSDe is re-supplied to Aave
5. Steps 2-4 are repeated until reaching target leverage

## Vault APY calculation

## Understanding Leverage from LTV
```
LTV (Loan-to-Value) = 72%
```
This means:
- For every 100 sUSDe deposited
- You can borrow up to 72 USD worth of assets
- In our case, we borrow WETH

### 2. Maximum Leverage Calculation

Where:
- LTV (Loan-to-Value) = 72% for sUSDe on Aave V3

## APY Amplification

### 1. Base Yield Components
```
Base sUSDe APY = 29%
WETH Borrow Cost on Aave = 2.69%
```

### 2. Leveraged Yield Calculation
```
For 3x Leverage:
```
![image](https://github.com/user-attachments/assets/43e02342-e48f-419f-b2a2-36a7c63c06ed)

```
Components:
- Base sUSDe APY: 29%
- Target Leverage: 3x
- WETH Borrow APY: 2.69%
```





## Contract Functionality Explanation


### `deposit`

Allows users to deposit ETH into the vault. The ETH is wrapped as WETH, swapped to the vault's asset using Uniswap V3, and converted to vault shares. The shares are then minted and transferred to the receiver address.

### `withdraw`

Allows users to withdraw ETH by burning their vault shares. The function converts the shares back to the asset, swaps the asset to ETH using Uniswap V3, and transfers the ETH to the receiver address.

### `rebalance`

Rebalances the vault by supplying assets to Aave and borrowing additional assets. This function handles token swaps and ensures the vault's balance is adjusted according to the new strategy.

### `executeOperation`

Handles flash loan operations. It decodes the action type and parameters, performs the corresponding financial operation (rebalance, Withdraw from aave), and repays the flash loan with interest.

### `callVaultAction`

Triggers a flash loan from Aave and executes a specified vault action based on the provided parameters. This function is only callable by the governance address.


