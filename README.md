# Linked
Self-collateralized stablecoin. The goal is to create a stablecoin with minimal complexity. 

## Description
Linked is a self-collateralized stablecoin with minimal complexity and minimal collateral. The design is: 
**Token contract - ERC20**. The token contract has two limitations: 
- The tokens can't interact with contract addresses, only user addresses. This is to limit the DEX where the tokens can be traded. See point 2. 
- When transferred the tokens have a minimal fee in ETH and LKD (for example 0.1% ETH and 0.1% LKD above the gas cost). The minimal fee (ETH and LKD) will be send to the exchange contract. Users can buy or sell LKD on the DEX for the equivalent of 1 USD.

**Exchange contract**: 
- Only exchanges ETH - LKD.
- LKD for the equivalent of 1 USD. The price is determined by the oracle contract that gets the ETH price in USD from the decentralized chainlink oracle network.

The tokens will be airdropped to all ETH users. They can then choose to sell the coins on the DEX or use the coins. The benefit of this design is its simplicity and the linear increase in stability power when it is used more. Because more transactions is more collateral in the DEX for exchange.

The biggest stability risk is that centralized exchanges (not a DEX) will trade the coin for different prices. This is partly mitigated because it is hard for centralized exchanges to exchange (the tokens can't be handled with smart contracts). Further the fee on transfers gives an incentive to buy/sell on the DEX. If the price on the centralized exchanges differs there will be an arbitrage opportunity that will correct the price to the fixed 1 USD on the DEX.

### Instructions deployment ropsten
1. Install dependencies: `npm install truffle -g` & `npm install @truffle/hdwallet-provider`
2. Clone this repository.
3. Go to the local repository: `cd [path_folder_clone]`

4. Compile the contracts: `truffle compile`
5. Add ropsten to the truffle-config.js file.

6. Deploy the compiled contracts: `truffle migrate --network Ropsten`
7. Now you can interact with the deployed contracts.

### POC deployed contract
For the example deployment on Ropsten see:
- Token contract: 0xe19aAa87a8f352c505295abE749cF69614BEa434
- Oracle contract: 0xEb8d22c014dfC0021671973cfdeb1b05D0f03871
- Exchange contract: 0x7280De0Ae36b6363057efb4C130207a47e75Cb8C

Actions performed on POC:
- Update the ETH price of the oracle & exchange contract - using chainlink, transactionhash: 
*0x9feeadb9d43979415ef6acda33437f5a07e296c1f523806bd4e13c97f12adae4*
- Buy tokens from the exchange, transactionhash:
*0x137437e8546ee0932c07fe42b234fe2b609a9782a1de8087f4593a78bbb21dc6*
- Transfer tokens between two addresses + fee deduction to exchange, transactionhash:
*0xa3f0f944511d044ea127e0d546b0e358fab00741ee6ad8e487bc5e2af081e9db*
