# Velodrome

This repo contains the contracts for Velodrome Finance, an AMM on Optimism inspired by Solidly.

## Testing

This repo uses both Foundry (for Solidity testing) and Hardhat (for deployment).

Foundry Setup

```ml
forge init
forge build
forge test
```

Hardhat Setup

```ml
npm i
npx hardhat compile
```

## Deployment

This project's deployment process uses [Hardhat tasks](https://hardhat.org/guides/create-task.html). The scripts are found in `tasks/`.

Deployment contains 3 steps:

1. `npx hardhat deploy:op` which deploys the core contracts, along with RedemptionReceiver, to Optimism.

2. `npx hardhat deploy:ftm` which deploys the RedemptionSender contract to Fantom. The RedemptionReceiver address from Step 1 should be recorded in `deployed.ts` prior.

## Security

The Velodrome team engaged with Code 4rena for a security review. The results of that audit are available [here](https://code4rena.com/reports/2022-05-velodrome/). Our up-to-date security findings are located on our website [here](https://docs.velodrome.finance/security).

## Contracts

| Name               | Address                                                                                                                               |
| :----------------- | :------------------------------------------------------------------------------------------------------------------------------------ |
| WETH               | [0x4200000000000000000000000000000000000006](https://optimistic.etherscan.io/address/0x4200000000000000000000000000000000000006#code) |
| Velo               | [0x3c8B650257cFb5f272f799F5e2b4e65093a11a05](https://optimistic.etherscan.io/address/0x3c8B650257cFb5f272f799F5e2b4e65093a11a05#code) |
| MerkleClaim        | [0x00D59BC35174C3b250Dd92a363495d38C8777a49](https://optimistic.etherscan.io/address/0x00D59BC35174C3b250Dd92a363495d38C8777a49#code) |
| RedemptionSender   | [0x9809fB94eED086F9529df00d6f125Bf25Ee84A93](https://ftmscan.com/address/0x9809fB94eED086F9529df00d6f125Bf25Ee84A93#code)             |
| RedemptionReceiver | [0x846e822e9a00669dcC647079d7d625d2cd25A951](https://optimistic.etherscan.io/address/0x846e822e9a00669dcC647079d7d625d2cd25A951#code) |
| PairFactory        | [0x25CbdDb98b35ab1FF77413456B31EC81A6B6B746](https://optimistic.etherscan.io/address/0x25CbdDb98b35ab1FF77413456B31EC81A6B6B746#code) |
| BribeFactory       | [0xA84EA94Aa705F7d009CDDF2a60f65c0d446b748E](https://optimistic.etherscan.io/address/0xA84EA94Aa705F7d009CDDF2a60f65c0d446b748E#code) |
| GaugeFactory       | [0xC5be2c918EB04B091962fDF095A217A55CFA42C5](https://optimistic.etherscan.io/address/0xC5be2c918EB04B091962fDF095A217A55CFA42C5#code) |
| Voter              | [0x09236cfF45047DBee6B921e00704bed6D6B8Cf7e](https://optimistic.etherscan.io/address/0x09236cfF45047DBee6B921e00704bed6D6B8Cf7e#code) |
| VeloGovernor       | [0x64DD805aa894dc001f8505e000c7535179D96C9E](https://optimistic.etherscan.io/address/0x64DD805aa894dc001f8505e000c7535179D96C9E#code) |
| VotingEscrow       | [0x9c7305eb78a432ced5C4D14Cac27E8Ed569A2e26](https://optimistic.etherscan.io/address/0x9c7305eb78a432ced5C4D14Cac27E8Ed569A2e26#code) |
| VeArtProxy         | [0x5F2f6721Ca0C5AC522BC875fA3F09bF693dcFa1D](https://optimistic.etherscan.io/address/0x5F2f6721Ca0C5AC522BC875fA3F09bF693dcFa1D#code) |
| RewardsDistributor | [0x5d5Bea9f0Fc13d967511668a60a3369fD53F784F](https://optimistic.etherscan.io/address/0x5d5Bea9f0Fc13d967511668a60a3369fD53F784F#code) |
| Minter             | [0x3460Dc71A8863710D1C907B8d9D5DBC053a4102d](https://optimistic.etherscan.io/address/0x3460Dc71A8863710D1C907B8d9D5DBC053a4102d#code) |
