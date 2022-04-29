# Shared Wallet
A shared wallet contract implementation on Starknet.

_Disclaimer: This code is not intended for production use and has not been audited or tested thoroughly. This is just an initial experiment_

## Description
The purpose of this project is to create a shared fund across multiple accounts where each account owns a share. The shareholders influence the composition of the fund via governance and can withdraw what is owed to them at anytime.

This project provides the following:

- Contracts that act as an infinite token fund with ERC20 and ERC721 share implementations.
  - Accepts an array of owners that can add and remove from the fund
  - Accepts an array of tokens for the fund composition
  - Accepts an array of weights for the balance of this composition
  - Function that allows deposits of funds and distributes shares
  - Function that allows withdrawal of funds according to the shares held
- Contracts that implements governance mechanisms for proposing fund allocation.
  - Allows proposal to be made by anyone already holding a share certificate
  - Implements share defined voting power (other strategies customisable)
  - Proposal execution of swapping dummy tokens on AMM (***TBD***)
  - Keepers to automate proposal finalisation (***TBD***)
- Contract that handles incentivisation for positive return proposals for the fund - ***TBD***

## Setup

```
python3.7 -m venv venv
source venv/bin/activate
python -m pip install cairo-nile
nile install
```

## Acknowledgements

[perama](https://twitter.com/eth_worm) for their notes on [Cairo](https://perama-v.github.io/cairo/intro/)

[sambarnes](https://twitter.com/__________sam__), for their work on [cairo-dutch](https://github.com/sambarnes/cairo-dutch), used for openzeppelin account compatible signing logic

[snapshot-labs](https://github.com/snapshot-labs/sx-core) for the governance contracts template
