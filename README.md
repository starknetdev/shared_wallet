# Shared Wallet
A shared wallet contract implementation on Starknet.

_Disclaimer: This code is not intended for production use and has not been audited or tested thoroughly. This is just an initial experiment_

## Description
This project looks to provide the following:

- A wallet where shares can be distributed to stakeholders.
- A wallet where managers can control the funding strategy of the wallet.

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
