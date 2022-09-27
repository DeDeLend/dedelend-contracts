import {HardhatRuntimeEnvironment} from "hardhat/types"

async function deployment(hre: HardhatRuntimeEnvironment): Promise<void> {
  const {deployments} = hre
  const {save, getArtifact} = deployments

  save("HegicStrategyOTM_CALL_110_ETH", {
    address: "0xcfd2C370649dc6207E67d46D0f31f7B2adAf8484",
    abi: await getArtifact("IHegicStrategy").then((x) => x.abi),
  })
  save("HegicStrategyOTM_CALL_120_ETH", {
    address: "0x6409CEE09a0d2dCe8AA4Da2a7E1cA1A3351AFB7C",
    abi: await getArtifact("IHegicStrategy").then((x) => x.abi),
  })
  save("HegicStrategyOTM_CALL_130_ETH", {
    address: "0xE88595bCF5ee129AB619c388c91d5CC2Ce3eF7F1",
    abi: await getArtifact("IHegicStrategy").then((x) => x.abi),
  })
  save("HegicStrategyOTM_CALL_110_BTC", {
    address: "0xc8715eAB195CE1dF628ce3B89B63F3849a55Ffe9",
    abi: await getArtifact("IHegicStrategy").then((x) => x.abi),
  })
  save("HegicStrategyOTM_CALL_120_BTC", {
    address: "0x9F7e2a3dcf8Ba93B00EE5d3aF2419ebc1DBb6256",
    abi: await getArtifact("IHegicStrategy").then((x) => x.abi),
  })
  save("HegicStrategyOTM_CALL_130_BTC", {
    address: "0xAc28e549e5D61Ecb586f7FEE51Bcbf454591b082",
    abi: await getArtifact("IHegicStrategy").then((x) => x.abi),
  })

  save("HegicStrategyOTM_PUT_70_ETH", {
    address: "0xd90bB7bAB3dd51e3975c3A21a501D281AF969380",
    abi: await getArtifact("IHegicStrategy").then((x) => x.abi),
  })
  save("HegicStrategyOTM_PUT_80_ETH", {
    address: "0x6C8e62f6d0CEE278cb1EeA2E5B9F27a5787b9A61",
    abi: await getArtifact("IHegicStrategy").then((x) => x.abi),
  })
  save("HegicStrategyOTM_PUT_90_ETH", {
    address: "0x18448c71653FFd8196162c830d6aAC1752b759F7",
    abi: await getArtifact("IHegicStrategy").then((x) => x.abi),
  })
  save("HegicStrategyOTM_PUT_70_BTC", {
    address: "0xB3C9DEac7c37d7144f61166baf91f5682fae7338",
    abi: await getArtifact("IHegicStrategy").then((x) => x.abi),
  })
  save("HegicStrategyOTM_PUT_80_BTC", {
    address: "0x824081Cd6397aBD018cfc039440594b832De8d2c",
    abi: await getArtifact("IHegicStrategy").then((x) => x.abi),
  })
  save("HegicStrategyOTM_PUT_90_BTC", {
    address: "0x7a4aF7AAF60292461098edDFA63e4095144331ff",
    abi: await getArtifact("IHegicStrategy").then((x) => x.abi),
  })
}

deployment.tags = ["test-single", "single-otm"]

export default deployment
