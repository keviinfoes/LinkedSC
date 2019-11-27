/** Exchange contract for the linked stablecoin.
*
*  This is the only accepted exchange between ETH and the stablecoin. The exchange
*  takes the oracle price input for ETH in USD. Then fixes the price between the
*  stablecoin and Ether on 1 stablecoin for 1 USD (in ETH)
*
*
*/

pragma solidity ^0.5.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./LinkedICUST.sol";

contract LinkedEXC {
    using SafeMath for uint256;
  
    IERC20 public token;
    CUSTODIAN public cust;
    address public owner;
    
    uint public rate = 1; // Initial rate -> adjusts based on oracle input
    address public oraclecontract;
    address payable public custodian;
    address payable public tokenadd;
    
    uint256 public indexBuys;
    uint256 public indexSells;
    uint256 _feeETH = 1 * 1 finney;

    event BuyToken(address user, uint amount, uint costWei, uint balance);
    event SellToken(address user, uint amount, uint costWei, uint balance);
    event UpdateRate(uint256 Rate);
    
    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }
  
    /**
    * constructor
    */
    constructor() public {
        owner = msg.sender;
    }
  
    /**
    * Fallback function. Used to load the exchange with ether
    */
    function() external payable {}
  
    /**
    * Set oracle address
    */
    function changeOracleAddress(address OracleAddress) onlyOwner public returns (bool success) {
        require (OracleAddress != address(0));
        oraclecontract = OracleAddress;
        return true;
    }
    /**
    * Set token address
    */
    function changeTokenAddress(address tokenContractAddr) onlyOwner public returns (bool success) {
       require (tokenContractAddr != address(0));
       token = IERC20(tokenContractAddr);
       return true;
    }
    /**
    * Set custodian address
    */
    function changeCustodianAddress(address payable custodianContractAddr) onlyOwner public returns (bool success) {
       require (custodianContractAddr != address(0));
       custodian = custodianContractAddr;
       cust = CUSTODIAN(custodianContractAddr);
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
    * Sender requests to buy [amount of] tokens from the contract.
    * Sender needs to send enough ether to buy the tokens at a price of amount / rate
    */
    function addBuyOrder(uint amount, uint raterequest) payable public returns (bool success) {
        //Check for changes in the rate between order and rate in contract
        //If raterequest is 0 then the order is executed against the current rate.
        if (raterequest == 0) {
            raterequest = rate;
        }
        require(rate == raterequest, "exchange buy order: rate is not requested rate");
        uint costWei = (amount).div(rate);
        require(msg.value >= _feeETH.add(costWei), "exchange buy order: not enough funds send");
        matchingOrdersBuy(amount, costWei);
        indexBuys += 1;
        emit BuyToken(msg.sender, amount, costWei, token.balanceOf(msg.sender));
        return true;
    }
    
    /**
    * Sender requests to sell [amount of] tokens from the contract.
    * Sender needs to have enough tokens to sell the tokens at a price of amount / rate
    */
    function addSellOrder(uint amount, uint raterequest) payable public returns (bool success) {
        //Check for changes in the rate between order and rate in contract
        //If raterequest is 0 then the order is executed against the current rate.
        if (raterequest == 0) {
            raterequest = rate;
        }
        require(rate == raterequest,"exchange sell order: rate is not requested rate");
        uint costWei = (amount).div(rate);
        require(token.balanceOf(msg.sender) >= amount, "exchange sell order: not enough token funds");
        matchingOrdersSell(amount, costWei);
        indexSells += 1;
        emit SellToken(msg.sender, amount, costWei, token.balanceOf(msg.sender));
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
        //Check amount ETH of user for transaction
        require(msg.value >= _feeETH.add(costWei), "exchange matching buy: not enough funds send");
        uint change = msg.value.sub(_feeETH.add(costWei));
        tokenadd.transfer(_feeETH); 
        //Send costWei to custodian contract
        custodian.transfer(costWei);
        //Send the tokens to the user and return change to the user 
        assert(cust.mint(msg.sender, amount));
        msg.sender.transfer(change);
        return true;  
    }
    function matchingOrdersSell(uint amount, uint costWei) internal returns (bool success) {
        require(custodian.balance >= costWei, "exchange matching sell: not enough funds for transfer");
        //Burn tokens to custodian
        assert(cust.burn(msg.sender, amount));
        //Send ETH to recipient using the custodian function
        assert(cust.transfer(msg.sender, costWei));
        return true;  
    }
}
