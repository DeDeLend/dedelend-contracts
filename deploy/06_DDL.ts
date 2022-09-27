import {HardhatRuntimeEnvironment} from "hardhat/types"

async function deployment(hre: HardhatRuntimeEnvironment): Promise<void> {
  const {deployments, getNamedAccounts, network} = hre
  const {deploy, get} = deployments
  const {deployer} = await getNamedAccounts()
  const optionsManger = await get("OptionsManager")
  const Pool = await get("HegicOperationalTreasury")
  const USDC = await get("USDC")

  let arrCALL_ETH = [
    (await get("HegicStrategyATM_CALL_ETH")).address,
    (await get("HegicStrategyOTM_CALL_110_ETH")).address,
    (await get("HegicStrategyOTM_CALL_120_ETH")).address,
    (await get("HegicStrategyOTM_CALL_130_ETH")).address,
  ]

  let arrCALL_BTC = [
    (await get("HegicStrategyATM_CALL_BTC")).address,
    (await get("HegicStrategyOTM_CALL_110_BTC")).address,
    (await get("HegicStrategyOTM_CALL_120_BTC")).address,
    (await get("HegicStrategyOTM_CALL_130_BTC")).address,
  ]

  let arrPUT_ETH = [
    (await get("HegicStrategyATM_PUT_ETH")).address,
    (await get("HegicStrategyOTM_PUT_70_ETH")).address,
    (await get("HegicStrategyOTM_PUT_80_ETH")).address,
    (await get("HegicStrategyOTM_PUT_90_ETH")).address,
  ]

  let arrPUT_BTC = [
    (await get("HegicStrategyATM_PUT_BTC")).address,
    (await get("HegicStrategyOTM_PUT_70_BTC")).address,
    (await get("HegicStrategyOTM_PUT_80_BTC")).address,
    (await get("HegicStrategyOTM_PUT_90_BTC")).address,
  ]

  const paramsETH = {
    arr_call: arrCALL_ETH,
    arr_put: arrPUT_ETH,
    currency: "ETH",
    collateralToken: optionsManger.address,
    operationalPool: Pool.address,
    usdc: USDC.address,
    minBorrowLimit: 1e6,
    ltv: 5000,
    collateralDecimals: 18, 
    PriorLiqPriceCoef: 4
  }

  const paramsBTC = {
    arr_call: arrCALL_BTC,
    arr_put: arrPUT_BTC,
    currency: "BTC",
    collateralToken: optionsManger.address,
    operationalPool: Pool.address,
    usdc: USDC.address,
    minBorrowLimit:  1e6,
    ltv:  5000,
    collateralDecimals: 8,
    PriorLiqPriceCoef: 3
  }
  async function deployDDL(params: typeof paramsETH) {
    const contractName = `DDL_${params.currency}`
    await deploy(contractName, {
      contract: "DDL",
      from: deployer,
      // gasLimit: network.name == "arbitrum_ddl" ? "250000000" : undefined,
      log: true,
      args: [
        params.arr_call,
        params.arr_put,
        params.collateralToken,
        params.operationalPool,
        params.usdc,
        params.minBorrowLimit,
        params.ltv,
        params.collateralDecimals,
        params.PriorLiqPriceCoef
      ],
    })
  }
  await deployDDL({
    ...paramsETH,
  })
  await deployDDL({
    ...paramsBTC,
  })
}

deployment.tags = ["test-single", "ddl"]
deployment.dependencies = [
  "single-atm",
  "single-otm",
  "operational-treasury",
  "options-manager",
]

export default deployment
