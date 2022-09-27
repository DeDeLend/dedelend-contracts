import {HardhatRuntimeEnvironment} from "hardhat/types"

async function deployment(hre: HardhatRuntimeEnvironment): Promise<void> {
  const {deployments} = hre
  const { save, getArtifact } = deployments

  save("PriceProviderBTC", {
    address: "0x6ce185860a4963106506C203335A2910413708e9",
    abi: await getArtifact("@chainlink/contracts/src/v0.7/interfaces/AggregatorV3Interface.sol:AggregatorV3Interface").then((x) => x.abi),
  })
  save("PriceProviderETH", {
    address: "0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612",
    abi: await getArtifact("@chainlink/contracts/src/v0.7/interfaces/AggregatorV3Interface.sol:AggregatorV3Interface").then((x) => x.abi),
  })
}

deployment.tags = ["test-single", "single-prices"]

export default deployment
