import {HardhatRuntimeEnvironment} from "hardhat/types"

async function deployment(hre: HardhatRuntimeEnvironment): Promise<void> {
  const {deployments} = hre
  const { save, getArtifact} = deployments

  save("USDC", {
    address: "0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8",
    abi: await getArtifact("@openzeppelin/contracts/token/ERC20/ERC20.sol:ERC20").then((x) => x.abi),
  })
}

deployment.tags = ["test-single", "single-tokens"]
export default deployment
