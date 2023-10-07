// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract RDGVip is Initializable, ERC721EnumerableUpgradeable {
   uint256 public maxSupply;
   uint256 private _tokenIdCounter;
   string private uri;

   function initialize(
      string memory _name,
      string memory _symbol,
      string memory _uri,
      uint256 _maxSupply
   ) public initializer {
      __ERC721_init(_name, _symbol);
      maxSupply = _maxSupply;
      uri = _uri;
      _tokenIdCounter = 0;
   }

   modifier onlyMint() {
      require(_tokenIdCounter < maxSupply, "Max supply reacthed");
      _;
   }

   function mint(address _to) external onlyMint {
      _tokenIdCounter += 1;
      uint256 tokenId = _tokenIdCounter;
      _safeMint(_to, tokenId);
   }

   function tokenURI(
      uint256 tokenId
   ) public view virtual override returns (string memory) {
      _requireOwned(tokenId);

      string memory baseURI = _baseURI();
      return
         bytes(baseURI).length > 0
            ? string.concat(baseURI, Strings.toString(tokenId), ".json")
            : "";
   }

   function _baseURI() internal view virtual override returns (string memory) {
      return uri;
   }
}
