const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-network-helpers");
// const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { ethers } = require("hardhat");
// const https = require('https');

describe("SUSDEVault", function () {

  let asset, weth, accounts, user, vault

  beforeEach(async function () {
    asset = "0x9d39a5de30e57443bff2a8307a4256c8797a3497"
    const addressProvider = "0x2f39d218133AFaB8F2B819B1066c7E434Ad94E9e"
    weth = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"

    const Vault = await ethers.getContractFactory("SUSDEVault");
    vault = await Vault.deploy(
      asset,
      addressProvider,
      weth,
      50000,
      // {gasLimit: 10000000}
    );

    accounts = await ethers.getSigners();
    user = await accounts[0].getAddress();
  })



  describe("deposit and rebalance", function () {
    it("rebalance", async function () {
      let amount = ethers.utils.parseEther("0.32873");

      let wethContract = await hre.ethers.getContractAt("IWETH9", weth);
      // await wethContract.deposit({value: amount})

      // await wethContract.approve(vault.address, amount)
      
      let assetContract = await hre.ethers.getContractAt("IERC20", asset);
      const balBefore = await assetContract.balanceOf(vault.address)
      console.log("balBefore : ", balBefore.toString())
      
      await assetContract.approve(vault.address, amount)
          
      const tx = await vault.connect(accounts[0]).deposit(amount.toString(), user, {gasLimit: 10000000});
      await tx.wait();

      const balAfter = await assetContract.balanceOf(vault.address)
      console.log("balAfter : ", balAfter.toString())

      const shares = await vault.balanceOf(user);
      console.log("Share bal : ", shares.toString())

      const totals = await vault.totalSupply()
      const totalAssets = await vault.totalAssets()
      const coll = await vault.getCollateralAssetBalance()
      // const price = await vault.getAssetPriceFromAave(asset)
      console.log("console ", totals.toString(), totalAssets.toString(), coll.toString()) //, price[0].toString(), price[1].toString() )

      const abiCoder = new ethers.utils.AbiCoder();

      const types = [
        'uint256', // supplyAmount
        'uint256', // flAmount
        'uint256', // flAmountWithFee
        'uint256'  // slippagePercent
      ];

      const paramTypes = [
        'uint8', // vaultAction
        'bytes' // actionParam
      ];

      // get the balance of the asset in the vault
      const balAsset = await assetContract.balanceOf(vault.address)
      console.log("balAsset : ", balAsset.toString())
      
      // Define the values
      const supplyAmount = balAsset;//ethers.utils.parseEther("0.0848663"); //0.1697326
      const flAmount = ethers.utils.parseEther("0.000200568");
      const flAmountWithFee = 0;
      const slippagePercent = 50000;
      
      // Encode the values
      const encodedActionParams = abiCoder.encode(types, [supplyAmount, flAmount, flAmountWithFee, slippagePercent]);

      const encodedParams = abiCoder.encode(paramTypes, [0, encodedActionParams]);
    

      const tx1 = await vault.connect(accounts[0]).callVaultAction(weth, flAmount, encodedParams, {gasLimit: 10000000});
      await tx1.wait();
      
      const sharesAfter = await vault.balanceOf(user);
      console.log("Share bal after withdraw : ", sharesAfter.toString())

      
      const UserbalAfter = await wethContract.balanceOf(user)
      console.log("UserbalAfter : ", UserbalAfter.toString())

      let aToken = await hre.ethers.getContractAt("IAToken", "0x4579a27aF00A62C0EB156349f31B345c08386419");
      const abalance = await aToken.balanceOf(vault.address)
      console.log("supplyAmount : ", supplyAmount.toString())
      console.log("abalance : ", abalance.toString())
      
      let dToken = await hre.ethers.getContractAt("IDToken", "0xeA51d7853EEFb32b6ee06b1C12E6dcCA88Be0fFE");
      const dbalBefore = await dToken.balanceOf(vault.address)
      console.log("dbalBefore : ", dbalBefore.toString())


        
      // expect(ethers.utils.formatEther(borrowedAmount[2].toString())).to.equal("2.0");
      // expect(await stEthVault.balanceOf(user)).to.equal(amountWithoutFee);   

    });

  });
});


// to = 0x64b761d848206f447fe2dd461b0c635ec39ebb27
// admin = 0x5300A1a15135EA4dc7aD5a167152C01EFc9b192A
// supply cap = 68719476735
// 0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266 
// 0x9d39a5de30e57443bff2a8307a4256c8797a3497

  // describe("deposit", function () {
  //   it("Genesis deposit", async function () {
  //     let amount = ethers.utils.parseEther("0.1");

  //     let wethContract = await hre.ethers.getContractAt("IWETH9", weth);
  //     await wethContract.deposit({value: amount})

  //     await wethContract.approve(vault.address, amount)
      
  //     let assetContract = await hre.ethers.getContractAt("IERC20", asset);
  //     const balBefore = await assetContract.balanceOf(vault.address)

  //     console.log("balBefore : ", balBefore.toString())
          
  //     const tx = await vault.connect(accounts[0]).deposit(amount.toString(), user, {gasLimit: 10000000});
  //     await tx.wait();

  //     const balAfter = await assetContract.balanceOf(vault.address)
  //     console.log("balAfter : ", balAfter.toString())

  //     const shares = await vault.balanceOf(user);
  //     console.log("Share bal : ", shares.toString())

  //     const totals = await vault.totalSupply()
  //     const totalAssets = await vault.totalAssets()
  //     const coll = await vault.getCollateralAssetBalance()
  //     const price = await vault.getAssetPriceFromAave(asset)
  //     console.log("console ", totals.toString(), totalAssets.toString(), coll.toString(), price[0].toString(), price[1].toString() )

  //     const tx1 = await vault.connect(accounts[0]).withdraw(shares.toString(), user, user, {gasLimit: 10000000});
  //     await tx1.wait();
      
  //     const sharesAfter = await vault.balanceOf(user);
  //     console.log("Share bal after withdraw : ", sharesAfter.toString())

      
  //     const UserbalAfter = await wethContract.balanceOf(user)
  //     console.log("UserbalAfter : ", UserbalAfter.toString())
        
  //     // expect(ethers.utils.formatEther(borrowedAmount[2].toString())).to.equal("2.0");
  //     // expect(await stEthVault.balanceOf(user)).to.equal(amountWithoutFee);   

  //   });

  // });
