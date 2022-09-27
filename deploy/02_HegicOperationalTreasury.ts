import {HardhatRuntimeEnvironment} from "hardhat/types"

async function deployment(hre: HardhatRuntimeEnvironment): Promise<void> {
  const {deployments} = hre
  const {save, getArtifact} = deployments

  save("HegicOperationalTreasury", {
    address: "0xB0F9F032158510cd4a926F9263Abc86bAF7b4Ab3",
    abi: await getArtifact("IHegicOperationalTreasury").then((x) => x.abi),
  })
}

deployment.tags = ["test-single", "operational-treasury"]

export default deployment
