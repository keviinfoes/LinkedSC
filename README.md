# Linked
Self-collateralized stablecoin. The goal is to create a stablecoin with minimal complexity. 

## Description
Linked is a self-collateralized stablecoin with minimal complexity, minimal collateral and self-The design is: 
1. Token contract - ERC20. The token contract has two limitations: 
- The tokens can't interact with contract addresses, only user addresses. This is to limit the DEX where the tokens can be traded. See point 2. 
- When transferred the tokens have a minimal fee in ETH and LKD (for example 0.1% ETH and 0.1% LKD above the gas cost). The minimal fee (ETH and LKD) will be send to the exchange contract. Users can buy or sell LKD on the DEX for the equivalent of 1 USD.

2. Exchange contract: 
- only exchanges ETH.
- LKD for the equivalent of 1 USD. The price is determined by the oracle contract that gets the ETH price in USD from the decentralized chainlink oracle network.

3. The tokens will be airdropped to all ETH users. They can then choose to sell the coins on the DEX or use the coins.

The benefit of this design is its simplicity and the linear increase in stability power when it is used more. Because more transactions is more collateral in the DEX for exchange.

The biggest stability risk is that centralized exchanges (not a DEX) will trade the coin for different prices. This is partly mitigated because it is hard for centralized exchanges to exchange (the tokens can't be handled with smart contracts). Further the fee on transfers gives an incentive to buy/sell on the DEX. If the price on the centralized exchanges differs there will be an arbitrage opportunity that will correct the price to the fixed 1 USD on the DEX.
