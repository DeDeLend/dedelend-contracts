import { HardhatUserConfig } from "hardhat/types"
import "@nomiclabs/hardhat-waffle"
import "@nomiclabs/hardhat-etherscan"
import "hardhat-typechain"
import "hardhat-abi-exporter"
import "hardhat-deploy-ethers"
import "hardhat-local-networks-config-plugin"
import "hardhat-deploy"
import "hardhat-dependency-compiler"

const config: HardhatUserConfig = {
  localNetworksConfig: "~/.hardhat/networks.json",
  defaultNetwork: "hardhat",
  solidity: {
    compilers: [
      {
        version: "0.8.6",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    ],
  },
  namedAccounts: {
    deployer: {
      default: 0,
    },
  },
}

export default config
