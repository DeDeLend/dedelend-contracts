import {HardhatRuntimeEnvironment} from "hardhat/types"

async function deployment(hre: HardhatRuntimeEnvironment): Promise<void> {
  const {deployments} = hre
  const {save, getArtifact} = deployments

  save("HegicStrategyATM_CALL_ETH", {
    address: "0x75451c621CBa336eDe7DE12BC6AB28eA250C8371",
    abi: await getArtifact("IHegicStrategy").then((x) => x.abi),
  })
  save("HegicStrategyATM_PUT_ETH", {
    address: "0x8DaB85712CB6DeE470b72D6c54A3F8426010ce28",
    abi: await getArtifact("IHegicStrategy").then((x) => x.abi),
  })
  save("HegicStrategyATM_CALL_BTC", {
    address: "0xA321404B708682531B2a959c52AA8A53F35A14AE",
    abi: await getArtifact("IHegicStrategy").then((x) => x.abi),
  })
  save("HegicStrategyATM_PUT_BTC", {
    address: "0x83305A6B2B906704Ed042CBEFAfe94DBc3f185DD",
    abi: await getArtifact("IHegicStrategy").then((x) => x.abi),
  })
}

deployment.tags = ["test-single", "single-atm"]

export default deployment
