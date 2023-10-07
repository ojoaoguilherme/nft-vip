// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {RDGVip} from "./NFT.sol";

contract TokenSale is Initializable, ReentrancyGuardUpgradeable {
   RDGVip public nft;
   uint256 public salePrice;
   uint256 private fee;
   AggregatorV3Interface public priceFeed;

   function initialize(
      address _nft,
      uint256 _salePrice,
      address _priceFeed,
      uint256 _fee
   ) public initializer {
      nft = RDGVip(_nft);
      priceFeed = AggregatorV3Interface(_priceFeed);
      salePrice = _salePrice;
      fee = _fee;
   }

   /**
    * @dev Buy the NFT and sends a small amount of the purchase to `receiver`
    *
    */

   function buyToken(address payable receiver) external payable nonReentrant {
      // Put values on the stack
      uint256 matic = msg.value;
      uint256 price = tokenPrice();
      uint256 receiverFee = (price * fee) / 100;
      require(matic >= price, "Insufficient MATIC sent");

      // prettier-ignore
      (bool success, ) = payable(address(this)).call{value: matic - receiverFee}("");
      require(success == true, "Failed to buy token");

      (bool receiverSuccess, ) = receiver.call{value: receiverFee}("");
      require(receiverSuccess == true, "Failed to send receiver their fee");

      // Check if `msg.sender` sent more than enough
      uint256 remaining = matic - price;
      if (remaining > 0) {
         //prettier-ignore
         (bool sentRemaining, ) = payable(msg.sender).call{ value: remaining}("");
         require(sentRemaining == true, "Failed to sent back remaining MATIC");
      }

      // TODO Emit bought token
      nft.mint(msg.sender);
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
