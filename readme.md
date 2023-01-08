# Velocimeter

run this script after cloning the repo to get the openzeppelin contracts and foundry setup etc.

https://github.com/Velocimeter/instruments/blob/master/gitsubmodules.sh



Goerli


Velo deployed to:  0x41754Fd93201B64Cd7633a8e8f861D47594b29A8
GaugeFactory deployed to:  0x30Ba274c119865312c1417b6E1Be6C98DAceb6B2
BribeFactory deployed to:  0x4871E36eDEB6750e47f616C57e70a978ac9a9003
PairFactory deployed to:  0xB4AD2aAC39268687D62b36BD69fC532862CF6590
Router deployed to:  0x1584d57c849797fb752d3dc5071F49B59D6C7416
Args:  0xB4AD2aAC39268687D62b36BD69fC532862CF6590 0x4200000000000000000000000000000000000006

VelodromeLibrary deployed to:  0x83c08EE991D0010208a117b84F7ea412373AEB90
Args:  0x1584d57c849797fb752d3dc5071F49B59D6C7416

VeArtProxy deployed to:  0x944AF7785d57bcfC00e95388453B93DAD373216e
VotingEscrow deployed to:  0x2B0BB6962e89bD5FE9510Ff09Af8D709be21AAD7
Args:  0x41754Fd93201B64Cd7633a8e8f861D47594b29A8 0x944AF7785d57bcfC00e95388453B93DAD373216e

RewardsDistributor deployed to:  0xf4F344Cfa1A82eDD37C96E879f01D9CA03f385b9
Args:  0x2B0BB6962e89bD5FE9510Ff09Af8D709be21AAD7

Voter deployed to:  0x9f7fdaB9317f1442808B90B819Ed0a4eF4f74994
Args:  0x2B0BB6962e89bD5FE9510Ff09Af8D709be21AAD7 0xB4AD2aAC39268687D62b36BD69fC532862CF6590 0x30Ba274c119865312c1417b6E1Be6C98DAceb6B2 0x4871E36eDEB6750e47f616C57e70a978ac9a9003

Minter deployed to:  0x52A18b2386D6221Cf9DbcD4790456a23249e5279
Args:  0x9f7fdaB9317f1442808B90B819Ed0a4eF4f74994 0x2B0BB6962e89bD5FE9510Ff09Af8D709be21AAD7 0xf4F344Cfa1A82eDD37C96E879f01D9CA03f385b9

RedemptionReceiver deployed to:  0xfe873D4923b343F0D6BD98045a9C82D8dDEC511E
Args:  0x3e22e37Cb472c872B5dE121134cFD1B57Ef06560 0x41754Fd93201B64Cd7633a8e8f861D47594b29A8 10012 0x72aB53a133b27Fa428ca7Dc263080807AfEc91b5

VeloGovernor deployed to:  0x0bd9d21b40428a650DbFC0F7bd3F7B6FA321F915
Args:  0x2B0BB6962e89bD5FE9510Ff09Af8D709be21AAD7

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
