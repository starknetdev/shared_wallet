# Shared Wallet
An shared wallet contract implementation on Starknet.

_Disclaimer: This code is not intended for production use and has not been audited or tested thoroughly. This is just an initial experiment_

## Setup

```
python3.7 -m venv venv
source venv/bin/activate
python -m pip install cairo-nile
nile install
```

## Issues

Verifying ecdsa signature not currently working

## Acknowledgements

[perama](https://twitter.com/eth_worm) for their notes on [Cairo](https://perama-v.github.io/cairo/intro/)

[sambarnes](https://twitter.com/__________sam__), for their work on [cairo-dutch](https://github.com/sambarnes/cairo-dutch), used for openzeppelin account compatible signing logic