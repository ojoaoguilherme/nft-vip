import { ethers, upgrades } from "hardhat";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";

const name = "Rotas do Garimpo VIP";
const symbol = "RDGVP";
const supply = 500;
const tokenUri = "https://rotasdogarimpo.com/nft/vip/";

describe("Testing NFT VIP", function () {
   let cut;
   async function deployProxy() {
      const NFT = await ethers.getContractFactory("RDGVip");
      cut = await upgrades.deployProxy(NFT, [name, symbol, tokenUri, supply]);
      await cut.waitForDeployment();
      return {
         cut,
      };
   }

   async function deployMintedSupply() {
      const [owner] = await ethers.getSigners();
      const NFT = await ethers.getContractFactory("RDGVip");
      cut = await upgrades.deployProxy(NFT, [name, symbol, tokenUri, supply]);
      await cut.waitForDeployment();
      for (let index = 0; index < 500; index++) {
         await cut.mint(owner.address);
      }
      return {
         cut,
      };
   }

   it("should be deployed with correct name", async function () {
      const { cut } = await loadFixture(deployProxy);
      expect(await cut.name()).to.equal("Rotas do Garimpo VIP");
   });

   it("should be deployed with correct symbol ", async function () {
      const { cut } = await loadFixture(deployProxy);
      expect(await cut.symbol()).to.equal("RDGVP");
   });

   it("should be deployed with correct uri", async function () {
      const { cut } = await loadFixture(deployProxy);
      const [owner] = await ethers.getSigners();
      await cut.mint(owner.address);
      expect(await cut.tokenURI(1)).to.equal(
         "https://rotasdogarimpo.com/nft/vip/1.json"
      );
   });

   it("should have max supply of 500", async function () {
      const { cut } = await loadFixture(deployMintedSupply);
      expect(await cut.totalSupply()).to.equal(500);
   });

   it("should revert if trying to mint more than max supply", async function () {
      const { cut } = await loadFixture(deployMintedSupply);
      const [owner] = await ethers.getSigners();
      expect(await cut.totalSupply()).to.equal(500);
      await expect(cut.mint(owner.address)).to.be.rejectedWith(
         "Max supply reacthed"
      );
   });
});
