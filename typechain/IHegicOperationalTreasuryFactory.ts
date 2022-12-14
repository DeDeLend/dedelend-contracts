/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import { Contract, Signer } from "ethers";
import { Provider } from "@ethersproject/providers";

import type { IHegicOperationalTreasury } from "./IHegicOperationalTreasury";

export class IHegicOperationalTreasuryFactory {
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): IHegicOperationalTreasury {
    return new Contract(
      address,
      _abi,
      signerOrProvider
    ) as IHegicOperationalTreasury;
  }
}

const _abi = [
  {
    inputs: [
      {
        internalType: "uint256",
        name: "id",
        type: "uint256",
      },
    ],
    name: "lockedLiquidity",
    outputs: [
      {
        internalType: "enum IHegicOperationalTreasury.LockedLiquidityState",
        name: "state",
        type: "uint8",
      },
      {
        internalType: "address",
        name: "strategy",
        type: "address",
      },
      {
        internalType: "uint128",
        name: "negativepnl",
        type: "uint128",
      },
      {
        internalType: "uint128",
        name: "positivepnl",
        type: "uint128",
      },
      {
        internalType: "uint32",
        name: "expiration",
        type: "uint32",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
];
