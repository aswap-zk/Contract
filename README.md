# ASwap Program 

ASWAP is a decentralized exchange (DEX) built on top of the Aleo blockchain. It leverages the unique features of the Aleo blockchain to offer enhanced privacy and new functionalities to both the DEX and its users.

## Introduction

The ASWAP contract facilitates decentralized trading and the provision of liquidity for ALEO and a variety of cross-chain token pairs. This enables users to exchange tokens, supply liquidity to pools, and access staking features. The use of smart contract events enhances the transparency and traceability of all actions executed within the contract. Participants can add to liquidity pools, trade ALEO with different tokens, and stake their tokens to accumulate rewards.

## Functions


### Aswap Contract

![Cross chain - Liquidity pool provision process](https://github.com/aswap-zk/.github/assets/96057861/a9b7b98f-95a9-4fa0-a05f-6668a40d7c72)
- **Pair Add Liquidity**: Initialize or add to ALEO pairs and token pairs liquidity pools
- **Single Asset Liquidity Providing**: Add a single token asset to the pool, and the Aswap contract can automatically input this with the appropriate ratio in the pool. 

![Cross chain - Swap pool](https://github.com/aswap-zk/.github/assets/96057861/986f4aae-a57a-454f-abe9-2f8b0029c58f)
- **Token Swap**: Execute swaps between ALEO and other tokens or between any two supported tokens.



### Aswap Staking Contract
![Cross chain - Staking](https://github.com/aswap-zk/.github/assets/96057861/93a4ee31-4d20-451a-9ad2-40e5da58c87c)
- **Stake ALEO**: Lock ALEO into the contract to earn rewards.
- **Stake Other Assets**: Aswap contract support user who want to stake other assets directly 
- **Earn rewards**: Claim accrued rewards.

