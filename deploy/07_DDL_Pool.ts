import {HardhatRuntimeEnvironment} from "hardhat/types"

async function deployment(hre: HardhatRuntimeEnvironment): Promise<void> {
  const {deployments, getNamedAccounts, network} = hre
  const {deploy, get, execute} = deployments
  const {deployer} = await getNamedAccounts()
  const ddl_eth = await get("DDL_ETH")
  const ddl_btc = await get("DDL_BTC")
  const USDC = await get("USDC")

  const ddl_pool = await deploy("DDL_POOL", {
    contract: "PoolDDL",
    from: deployer,
    gasLimit: network.name == "arbitrum_ddl" ? "250000000" : undefined,
    log: true,
    args: [
      USDC.address,
      ddl_eth.address,
      ddl_btc.address
    ],
  })

  await execute(
    "DDL_ETH",
    {log: true, from: deployer},
    "setPool",
    ddl_pool.address,
  )

  await execute(
    "DDL_BTC",
    {log: true, from: deployer},
    "setPool",
    ddl_pool.address,
  )
}

deployment.tags = ["test-single", "ddl-pool"]
deployment.dependencies = [
  "ddl",
  "single-atm",
  "single-otm",
  "operational-treasury",
  "options-manager",
]

export default deployment
