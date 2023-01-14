# Velocimeter

run this script after cloning the repo to get the openzeppelin contracts and foundry setup etc.

https://github.com/Velocimeter/instruments/blob/master/gitsubmodules.sh



{
  BribeFactory: '0x5542edb529F7c963583e9B8e5339121cFCf4B606',
  GaugeFactory: '0x1Ac3032Dfd7e206BA6d08F453f38593b9A583052',
  MerkleClaim: '0x0a68F78212D69EfC6346B5F9d72BC5A301779BE9',
  Minter: '0xd2C3ebFB8e7e79CA84080a8551D86Df50B0F559d',
  PairFactory: '0x7488AC81DC3908ff7141db4949e70D60A3Fd4DCc',
  RedemptionReceiver: '0x08e352f2130d4b68d7B1264CD42191205B61b60f',
  RewardsDistributor: '0xf6CdA702C6Bd15d5C0A325CE8f9f88219fE5F445',
  Router: '0xCeaEA7A5cB3e7521DdE6717BCc99a4c8c60E07b6',
  VeArtProxy: '0x5e7569D02214289490d16bCE4F96B38071db1aD8',
  Velo: '0xe69b00A164047e7eB87B73971B0f340eEbFF9c81',
  VeloGovernor: '0x588ADD83f24690BceEbaa4266cd8DC65709DDa4d',
  VelodromeLibrary: '0x233ed5d7FAed19F7b8A28844E2845FBF0F145Be2',
  Voter: '0x574607c69f369f0535E77C5F7C35767Aee04879A',
  VotingEscrow: '0x6b938BA22FB5520fFB5D14c9C4Fef82a48761497'
}

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
