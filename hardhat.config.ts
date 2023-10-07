import "@openzeppelin/hardhat-upgrades";
import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-chai-matchers";
import { HardhatUserConfig } from "hardhat/config";

const config: HardhatUserConfig = {
   networks: {
      hardhat: {
         forking: {
            url: "https://polygon-mumbai.g.alchemy.com/v2/XayCXo6oFDxnTlU-onyYNCtarlF3ESFp",
            blockNumber: 40948339,
         },
      },
   },
   solidity: {
      compilers: [
         {
            version: "0.8.20",
            settings: {
               optimizer: {
                  enabled: true,
                  runs: 1000,
               },
            },
         },
         {
            version: "0.7.6",
            settings: {
               optimizer: {
                  enabled: true,
                  runs: 1000,
               },
            },
         },
      ],
   },
};

export default config;
