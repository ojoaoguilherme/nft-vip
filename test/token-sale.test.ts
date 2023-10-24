import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { formatEther, formatUnits } from "ethers";
import { ethers, upgrades } from "hardhat";
import { RDGVip, TokenSale } from "../typechain-types";
import { Swap } from "../typechain-types/contracts/Swap.sol";

// MATIC/USD (MUMBAI) - 0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada
// MATIC/USD (MAINNET) - 0xAB594600376Ec9fD91F8e885dADF0CE036862dE0

const name = "Rotas do Garimpo VIP";
const symbol = "RDGVP";
const supply = 500;
const tokenUri = "https://rotasdogarimpo.com/nft/vip/";

const MATIC_USD_PRICE_FEED = "0xAB594600376Ec9fD91F8e885dADF0CE036862dE0";

const WMATIC_TOKEN = "0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270";
const DAI_TOKEN = "0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063";

const walletExample = "0x77bCE4769851fF24A13c1616EAD06a21431baE93";

describe("Testando o Token Sale", function () {
   async function deployContracts() {
      // Deploying NFT
      const ERC721 = await ethers.getContractFactory("RDGVip");

      const nft = (await upgrades.deployProxy(ERC721, [
         name,
         symbol,
         tokenUri,
         supply,
      ])) as unknown as RDGVip;
      await nft.waitForDeployment();

      // Deploying W - Matic
      const wmatic = await ethers.getContractAt("IERC20", WMATIC_TOKEN);
      await wmatic.waitForDeployment();

      // Deploying DAI
      const dai = await ethers.getContractAt("IERC20", DAI_TOKEN);
      await dai.waitForDeployment();

      // Token Sale arguments
      const nftSalePrice = ethers.parseEther("100");

      // Deploying Swap contract
      const swap = (await ethers.deployContract("Swap", [
         "0xE592427A0AEce92De3Edee1F18E0157C05861564",
      ])) as unknown as Swap;
      await swap.waitForDeployment();

      // Deploying Token Sale
      const TokenSale = await ethers.getContractFactory("TokenSale");
      const cut = (await upgrades.deployProxy(TokenSale, [
         nft.target,
         nftSalePrice,
         MATIC_USD_PRICE_FEED,
         400,
         WMATIC_TOKEN,
         swap.target,
         DAI_TOKEN, // DAI
         walletExample,
         walletExample,
         walletExample,
         walletExample,
      ])) as unknown as TokenSale;
      await cut.waitForDeployment();

      return { cut, nft, wmatic, swap, dai };
   }

   it("deve retornar o custo de uma NFT em MATIC", async function () {
      const { cut } = await loadFixture(deployContracts);
      expect(await cut.tokenPrice()).to.be.greaterThan(100);
   });

   it("deve ser possivel comprar uma NFT", async function () {
      const { cut, nft } = await loadFixture(deployContracts);
      const [owner, buyer] = await ethers.getSigners();
      const price = await cut.tokenPrice();

      // @ts-ignore ethers.js can only handle same function name this way
      await cut.connect(buyer)["buyToken(address payable)"](owner.address, {
         value: price,
      });
      expect(await nft.balanceOf(buyer.address)).to.be.equal(1);
   });

   it("deve mandar corretamente os MATIC para beneficiario", async function () {
      const { cut, nft } = await loadFixture(deployContracts);
      const [owner, buyer] = await ethers.getSigners();
      const price = await cut.tokenPrice();

      await expect(() =>
         // @ts-ignore ethers.js can only handle same function name this way
         cut.connect(buyer)["buyToken(address payable)"](owner.address, {
            value: price,
         })
      ).to.changeEtherBalance(
         buyer,
         ethers.parseEther("-194.648456031901636193")
      );

      await expect(() =>
         // @ts-ignore ethers.js can only handle same function name this way
         cut.connect(buyer)["buyToken(address payable)"](owner.address, {
            value: price,
         })
      ).to.changeTokenBalance(nft, buyer, 1);
   });

   it("deve converter MATIC => DAI", async function () {
      const { cut, dai } = await loadFixture(deployContracts);
      const [owner, buyer] = await ethers.getSigners();
      const price = await cut.tokenPrice();

      // @ts-ignore ethers.js can only handle same function name this way
      await cut.connect(buyer)["buyToken(address payable)"](owner.address, {
         value: price,
      });

      expect(await dai.balanceOf(cut.target)).to.be.greaterThan(0);
   });

   it("deve ser calculado corretamente ao vender NFT", async function () {
      const { cut, dai } = await loadFixture(deployContracts);
      const tokenPrice = parseFloat(formatEther(await cut.tokenPrice()));
      const comissionFee = (tokenPrice * 4) / 100;
      const tokenSaleIncome = tokenPrice - comissionFee;

      // tokenPrice =    194.6265
      // comissionFee =  7.785061
      // tokenSaleIncime = 186.84143

      expect(tokenSaleIncome).to.be.greaterThan(185).and.lessThan(188);
      // expect(tokenSaleIncome).to.be.greaterThan(185).and.lessThan(180); // teste false
   });
});
