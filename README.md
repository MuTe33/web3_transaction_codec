# web3 transaction codec

This is for testing eth tx decoding

## Getting Started

I found a ETH and ABI codec packages in Github. They were outdated and even the ABI was pre Flutter
2.0 version. So I started to update dependencies and update whole code. I merged both packages and 
deleted all encoding for the moment as I was only interested in decoding. This package still needs 
some more work. 

Here are the repos:

- [ETH codec](https://github.com/nbltrust/dart-eth-transaction-codec)
- [ABI codec](https://github.com/nbltrust/dart-eth-abi-codec)

## Some Notes

I have tested the package and could decode basic transactions. So far a transfer of coins, Uniswap
pool swap, buy/sell on opensea or any other contract which is attached to this package
(`src/data/contract_abi` folder) can be decoded. For some more advanced smart contracts like the buy/sell
opensea you need some more deeper decoding (as shown on the test file).

If you want to decode other stuff, you need to add the smart contract to `src/data/contract_abi` folder and
`src/data/contract_symbols.json`

I just have no time to port the rest of the code and clean it up plus adding these more advanced
decoding stuff as methods into the package. Feel free to do that, it's anyways forked from the
linked repos :)

Happy building!