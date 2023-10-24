// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {RDGVip} from "./NFT.sol";
import {Swap} from "./Swap.sol";

interface WMATIC {
   function deposit() external payable;

   function balanceOf(address) external returns (uint);

   function approve(address, uint256) external returns (bool);

   function allowance(address, address) external returns (uint256);
}

contract TokenSale is Initializable, ReentrancyGuardUpgradeable {
   RDGVip public nft;
   WMATIC public wmatic;
   uint256 public salePrice;
   uint256 private fee;
   AggregatorV3Interface public priceFeed;
   Swap private swapRouter;

   using SafeERC20 for IERC20;
   IERC20 public dai;

   address private joao;
   address private paguru;
   address private rogerio;
   address private ivan;
   address private rotas;

   function initialize(
      RDGVip _nft,
      uint256 _salePrice,
      AggregatorV3Interface _priceFeed,
      uint256 _fee,
      WMATIC _wmatic,
      Swap _swap,
      IERC20 _dai,
      address _joao,
      address _paguru,
      address _rogerio,
      address _rotas
   ) public initializer {
      nft = _nft;
      wmatic = _wmatic;
      priceFeed = _priceFeed;
      salePrice = _salePrice;
      fee = _fee;
      swapRouter = _swap;

      dai = _dai;
      joao = _joao;
      paguru = _paguru;
      rogerio = _rogerio;
      rotas = _rotas;
   }

   /**
    * @dev Buy the NFT and sends a small amount of the purchase to `receiver`
    *
    */

   function buyToken(address payable receiver) external payable nonReentrant {
      // Put values on the stack
      uint256 matic = msg.value;
      uint256 price = tokenPrice();
      console.log("Token Sale preco da NFT em MATIC", price);
      require(matic >= price, "Not enough matic to buy NFT");

      uint256 receiverFee = (price * fee) / 10000;
      console.log("Comissao do indicador em MATIC", receiverFee);
      uint256 fullIncome = price - receiverFee;

      console.log("MATIC restante para o swap DAI", fullIncome);

      //prettier-ignore
      (bool sentFullIncome, ) = payable(address(this)).call{value: matic}("");
      require(sentFullIncome == true, "Failed to send full income");

      (bool sentReceiverFee, ) = receiver.call{value: receiverFee}("");
      require(sentReceiverFee == true, "Failed to send receiver fee");

      // Check if `msg.sender` sent `msg.value` more than enough
      uint256 remaining = matic - price;

      if (remaining > 0) {
         //prettier-ignore
         (bool sentRemainingGas, ) = payable(msg.sender).call{value: remaining}("");
         require(
            sentRemainingGas == true,
            "Failed to send remaining gas to caller"
         );
      }

      // Convert MATIC to W - Matic
      wmatic.deposit{value: fullIncome}();

      uint256 wmaticBalance = wmatic.balanceOf(address(this));

      console.log("Swap MATIC <> W-MATIC");

      //
      require(
         wmatic.approve(address(swapRouter), wmaticBalance),
         "Failed to approve WMATIC"
      );

      //
      uint256 amountOut = swapRouter.swapExactInputSingle(wmaticBalance);
      console.log("Saldo DAI no contrato pra enviar partilhar");
      console.log(amountOut);

      // TODO send DAI to treasury

      nft.mint(msg.sender);
      // TODO Emit bought token
   }

   function sendTokensToWallets(uint256 amountIn) internal {
      uint256 teamBaseFee = (amountIn * 40) / 100; // 40%

      // investimento RDG
      uint256 treasuryFee = (amountIn * 60) / 100; //60%

      dai.safeTransfer(joao, teamBaseFee);
      dai.safeTransfer(ivan, teamBaseFee);
      dai.safeTransfer(paguru, teamBaseFee);
      dai.safeTransfer(rogerio, teamBaseFee);
      dai.safeTransfer(rotas, treasuryFee);
   }

   /**
    * @dev Buy the NFT
    */
   function buyToken() external payable nonReentrant {
      // Put values on the stack
      uint256 matic = msg.value;
      uint256 price = tokenPrice();

      require(matic >= price, "Insufficient MATIC sent");
      (bool success, ) = payable(msg.sender).call{value: matic}("");

      require(success == true, "Failed to buy token");

      // Check if `msg.sender` sent more than enough
      uint256 remaining = matic - price;
      if (remaining > 0) {
         //prettier-ignore
         (bool sentRemaining, ) = payable(address(this)).call{ value: remaining}("");
         require(sentRemaining == true, "Failed to sent back remaining MATIC");
      }

      // TODO Emit bought token
      nft.mint(msg.sender);
   }

   function tokenPrice() public view returns (uint256 nftPriceInMatic) {
      uint256 priceInUsd = salePrice;
      int256 maticPrice = getChainlinkDataFeedLatestAnswer();
      console.log("Valor MATIC em dolar", uint256(maticPrice));
      nftPriceInMatic = (priceInUsd * 1e18) / uint256(maticPrice * 1e10);
   }

   function getChainlinkDataFeedLatestAnswer() internal view returns (int) {
      // prettier-ignore
      (
            /* uint80 roundID */,
            int answer,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
      return answer;
   }

   receive() external payable {}

   fallback() external payable {}
}
