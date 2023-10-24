import "@openzeppelin/hardhat-upgrades";
import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-chai-matchers";
import { HardhatUserConfig } from "hardhat/config";

const config: HardhatUserConfig = {
   networks: {
      hardhat: {
         forking: {
            url: "https://polygon-mainnet.g.alchemy.com/v2/a3jXuouvJtMzPzTfYnjQcaZOHJzE-A_x",
            blockNumber: 48608156,
         },
         // loggingEnabled: true,
      },
   },
   solidity: {
      compilers: [
         {
            version: "0.7.6",
            settings: {
               optimizer: {
                  enabled: true,
                  runs: 1000,
               },
            },
         },
         {
            version: "0.8.20",
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
