import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { EtherSymbol } from "ethers";
import { ethers, upgrades } from "hardhat";
// MATIC/USD (MUMBAI) - 0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada
// MATIC/USD (MAINNET) - 0xAB594600376Ec9fD91F8e885dADF0CE036862dE0

const name = "Rotas do Garimpo VIP";
const symbol = "RDGVP";
const supply = 500;
const tokenUri = "https://rotasdogarimpo.com/nft/vip/";

const MATIC_USD_PRICE_FEED = "0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada";

describe("Testing Token Sale Contract", function () {
   async function deployContracts() {
      // Deploying NFT
      const ERC721 = await ethers.getContractFactory("RDGVip");
      const nft = await upgrades.deployProxy(ERC721, [
         name,
         symbol,
         tokenUri,
         supply,
      ]);
      await nft.waitForDeployment();

      // Token Sale arguments
      const nftAddress = await nft.getAddress();
      const nftSalePrice = ethers.parseEther("100");

      // Deploying Token Sale
      const TokenSale = await ethers.getContractFactory("TokenSale");
      const cut = await upgrades.deployProxy(TokenSale, [
         nftAddress,
         nftSalePrice,
         MATIC_USD_PRICE_FEED,
         4,
      ]);
      await cut.waitForDeployment();
      return { cut, nft };
   }

   it("should return the price of 1 NFT", async function () {
      const { cut } = await loadFixture(deployContracts);
      expect(await cut.tokenPrice()).to.be.greaterThan(100);
   });

   it("should be able to buy NFT", async function () {
      const { cut, nft } = await loadFixture(deployContracts);
      const [owner, buyer] = await ethers.getSigners();
      const price = await cut.tokenPrice();

      // @ts-ignore ethers.js can only handle same function name this way
      const buy = await cut
         .connect(buyer)
         ["buyToken(address payable)"](owner.address, {
            value: price,
         });
      expect(await nft.balanceOf(buyer.address)).to.be.equal(1);
   });

   it("buyer should pay 100 USD in matic value", async function () {
      const { cut, nft } = await loadFixture(deployContracts);
      const [owner, buyer] = await ethers.getSigners();
      const price = await cut.tokenPrice();

      await expect(() =>
         // @ts-ignore ethers.js can only handle same function name this way
         cut.connect(buyer)["buyToken(address payable)"](owner.address, {
            value: price,
         })
      ).to.changeEtherBalances(
         [buyer, cut, owner],
         [
            ethers.parseEther("-176.414593205677734324"),
            ethers.parseEther("169.358009477450624952"),
            ethers.parseEther("7.056583728227109372"),
         ]
      );
   });

   it.skip("should convert Matic price into USD from uniswap", async function () {});
});
