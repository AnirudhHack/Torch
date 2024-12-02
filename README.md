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

## Contract Flow Overview:

Users can deposit sUSDe tokens into the vault
The governance can manage leveraged positions on Aave using flash loans
Users can withdraw their share of assets

## Deposit Flow:

![image](https://github.com/user-attachments/assets/975dbe86-e7cc-4e49-b30b-d14cd59545b7)

1. User approves vault to spend their sUSDe tokens
2. Vault pulls sUSDe tokens from user
3. Calculates shares based on total assets
4. Mints vault tokens (shares) to receiver

## Rebalance Flow (Governance Only):
![image](https://github.com/user-attachments/assets/9d558721-863f-4b6e-9312-6f1601b4aecc)

1. Takes WETH flash loan
2. Swaps WETH → USDT → sUSDe
3. Supplies sUSDe to Aave
4. Borrows WETH from Aave
5. Repays flash loan with borrowed WETH

## Withdraw Flow:

1. Burns user's vault tokens (shares)
2. Calculates assets to return based on shares
3. Swaps sUSDe to WETH with slippage protection
4. Transfers WETH to receiver

## withdrawFromAave Flow (Governance Only):
The withdrawFromAave function is typically used in scenarios where the vault needs to reduce its position on Aave, either to return assets to users or to adjust its leverage. It ensures that the vault can manage its assets efficiently while maintaining the necessary liquidity and leverage levels.
1. Repay Borrowed WETH
2. Withdraw sUSDe from Aave


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
