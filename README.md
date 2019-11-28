# LinkedSC
This repository contains a self-collateralized stablecoin named linkedSC (LKS). LinkedSC is a stablecoin with minimal complexity. No Collateralized Debt Position (CDP), bonds, multiple coins or other complexities in the implementation. Simply the stablecoin and an exchange with a fixed price. The stability tax payed by the holders of the stabelcoin funds the exchange contract. This way the stability tax  guarantees the buy / sell of LKS for the equilivent of 1 USD (now or in the future) as long as the token is used.

## Description
The design of linkedSC is:
- **Token contract - ERC20**: The token contract has a embedded stability tax. The stability tax is divided in tax on holdings in LKS and transfer fee in ETH. The stability tax is send to the custodian contract. The custodian contracts reserves are available for the white listed exchanges. These exchanges have a fixed exchange rate for the equivalent of 1 USD per LKS.
- **Exchange contract**: The exchanges that use the stability reserve have a fixed exchange rate of 1 USD based on the used oracle.

## Benefits
The inital settings will be 2% inflation and ETH transfer fees (1 finney). Holders of the tokens can vote to adjust these settings. 

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

## Work in progress
- add front end.
- add voting contract. investigate: possible use of quadratic voting.
- investigate: use of multiple exchanges. The only difference between these exchanges is the oracle that is used. 

