/** Exchange contract for the linked stablecoin.
*
*  This is the only accepted exchange between ETH and the stablecoin. The exchange
*  takes the oracle price input for ETH in USD. Then fixes the price between the
*  stablecoin and Ether on 1 stablecoin for 1 USD (in ETH)
*
*
*/

pragma solidity ^0.4.24;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./LinkedORCL.sol";

contract LinkedEXC {
     using SafeMath for uint256;

     IERC20 public token;
     address public owner;

     uint public rate = 1; // Initial rate -> adjusts based on oracle input
     address public oraclecontract;
     uint256 public indexBuys;
     uint256 public indexSells;

     event BuyToken(address user, uint amount, uint costWei, uint balance);
     event SellToken(address user, uint amount, uint costWei, uint balance);
     event UpdateRate(uint256 Rate);

     /**
     * @dev Throws if called by any account other than the owner.
     */
     modifier onlyOwner() {
         require(msg.sender == owner);
         _;
     }

     /**
     * constructor
     */
     constructor(address tokenContractAddr) public {
         token = IERC20(tokenContractAddr);
         owner = msg.sender;
     }

     /**
     * Fallback function. Used to load the exchange with ether
     */
     function() public payable {}

     /**
     * Set oracle address
     */
     function changeOracleAddress(address OracleAddress) onlyOwner public returns (bool success) {
         require (OracleAddress != address(0));
         oraclecontract = OracleAddress;
         return true;
     }

         /**
     *  Updates the rate for a peg to 1 USD based on the oracle contract.
     *  The oracle contract uses the decentralised chainlink oracle implementation.
     */
     function updateRate(uint newRate) public returns (bool success) {
         require(msg.sender == oraclecontract);
         rate = newRate;
         emit UpdateRate(newRate);
         return true;
     }

     /**
     * Sender requests to buy [amount] of tokens from the contract.
     * Sender needs to send enough ether to buy the tokens at a price of amount / rate
     */
     function addBuyOrder(uint amount, uint raterequest) payable public returns (bool success) {
         //Check for changes in the rate between order and rate in contract
         //If raterequest is 0 then the order is executed against the current rate.
         if (raterequest == 0) {
             raterequest = rate;
         }
         require(rate == raterequest);
         uint costWei = (amount * 1 ether) / rate;
         require(msg.value >= costWei);
         matchingOrdersBuy(amount, costWei);
         emit BuyToken(msg.sender, amount, costWei, token.balanceOf(msg.sender));
         indexBuys += 1;
         return true;
     }

         /**
     * Sender requests to buy [amount] of tokens from the contract.
     * Sender needs to send enough ether to buy the tokens at a price of amount / rate
     */
     function addSellOrder(uint amount, uint raterequest) payable public returns (bool success) {
         //Check for changes in the rate between order and rate in contract
         //If raterequest is 0 then the order is executed against the current rate.
         if (raterequest == 0) {
             raterequest = rate;
         }
         require(rate == raterequest);
         uint costWei = (amount * 1 ether) / rate;
         require(token.balanceOf(msg.sender) >= amount);
         assert(token.transferFrom(msg.sender, this, amount));
         matchingOrdersSell(costWei);
         emit SellToken(msg.sender, amount, costWei, token.balanceOf(msg.sender));
         indexSells += 1;
         return true;
     }

     /**
     *  Matching functions - Buy and Sell
     *  The contract owns Tokens and ETH based on the fee in the token contract.
     *  This is to create automated buy / sell pressure for 1 USD per token.
     *
     *  The more the token is used, the more dept the contract has for the stabilisation
     *  of the token (sell/buy for 1 USD).
     */
     function matchingOrdersBuy(uint amount, uint costWei) internal returns (bool success) {
         require(token.balanceOf(this) >= amount);
         assert(token.transfer(msg.sender, amount));
         uint change = msg.value - costWei;
         msg.sender.transfer(change);
         return true;
     }
     function matchingOrdersSell(uint costWei) internal returns (bool success) {
         require(address(this).balance >= costWei);
         msg.sender.transfer(costWei);
         return true;
     }
 }
