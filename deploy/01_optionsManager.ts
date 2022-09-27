import {HardhatRuntimeEnvironment} from "hardhat/types"

async function deployment(hre: HardhatRuntimeEnvironment): Promise<void> {
  const {deployments, getNamedAccounts, network} = hre
  const {deploy, save, getArtifact} = deployments
  const {deployer} = await getNamedAccounts()

  save("OptionsManager", {
    address: "0x5B53d56c5a63ebBE852D9D911b7886A4338953f1",
    abi: await getArtifact("@openzeppelin/contracts/token/ERC721/ERC721.sol:ERC721").then((x) => x.abi),
  })

}

deployment.tags = ["test-single", "options-manager"]
export default deployment
