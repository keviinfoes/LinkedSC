# Linked
This repository contains a self-collateralized stablecoin named linked (LKS). Linked is a stablecoin with minimal complexity. No Collateralized Debt Position (CDP) or multiple coins needed in the implementation. The stability is maintained by the stability tax that guarantees the buy / sell of LKD for the equilivent of 1 USD (now or in the future) as long as the token is used.

## Description
The design of linked is:
- **Token contract - ERC20**: The token contract has a embedded stability tax. The stability tax is divided in inflation (1% total LKS) and transfer fee in ETH. The stability tax is send to the custodian contract. The custodian contracts reserves are available for the white listed exchanges. These exchanges have a fixed exchange for the equivalent of 1 USD per LKD.
- **Exchange contract**: Multiple exchanges can be added. The only difference between these exchanges is the oracle that is used. The exchanges that use the stability reserve have a fixed exchange rate of 1 USD based on the used oracle.

## Benefits
The use of multiple exchanges mitigates the risk of the oracles. Because if one oracle exchange is broken it can be paused and other exchanges will be used, selected by the users of LKS themself. The inital settings will be one exchange, 1% inflation and ETH transfer fees (multiple of the gas used). Holders of the tokens can vote to add / remove exchanges and adjust these settings. 

The benefit of the stability tax design is its simplicity and the limited need of collateral. The token is self-collateralized and the stability "power" increases when it is used more. Because more transactions is more collateral in the exchange.

## Instructions deployment ropsten
1. Install dependencies: `npm install truffle -g` & `npm install @truffle/hdwallet-provider`
2. Clone this repository.
3. Go to the local repository: `cd [path_folder_clone]`

4. Compile the contracts: `truffle compile`
5. Add ropsten to the truffle-config.js file.

6. Deploy the compiled contracts: `truffle migrate --network Ropsten`
7. Now you can interact with the deployed contracts.

### POC deployed contract - Ropsten
TBD

