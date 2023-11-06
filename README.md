# ASwap Program 

ASWAP is a decentralized exchange (DEX) built on top of the Aleo blockchain. It leverages the unique features of the Aleo blockchain to offer enhanced privacy and new functionalities to both the DEX and its users.

## Introduction

The ASWAP contract facilitates decentralized trading and the provision of liquidity for ALEO and a variety of cross-chain token pairs. This enables users to exchange tokens, supply liquidity to pools, and access staking features. The use of smart contract events enhances the transparency and traceability of all actions executed within the contract. Participants can add to liquidity pools, trade ALEO with different tokens, and stake their tokens to accumulate rewards.

## Functions


### Aswap Contract

![Cross chain - Liquidity pool provision process](https://github.com/aswap-zk/Contract/assets/58005728/37916ad1-0dc9-4973-b33d-3909b3b6fe75)
- **Pair Add Liquidity**: Initialize or add to ALEO pairs and token pairs liquidity pools
- **Single Asset Liquidity Providing**: Add a single token asset to the pool, and the Aswap contract can automatically input this with the appropriate ratio in the pool. 

![Cross chain - Swap pool](https://github.com/aswap-zk/Contract/assets/58005728/026bad35-b76e-473c-9f84-88eee432f147)
- **Token Swap**: Execute swaps between ALEO and other tokens or between any two supported tokens.



### Aswap Staking Contract
![Cross chain - Staking](https://github.com/aswap-zk/Contract/assets/58005728/8afc3ef9-4850-44df-8c7f-e9415eff4eda)
- **Stake ALEO**: Lock ALEO into the contract to earn rewards.
- **Stake Other Assets**: Aswap contract support user who want to stake other assets directly 
- **Earn rewards**: Claim accrued rewards.

