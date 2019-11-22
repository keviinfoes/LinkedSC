/**
*   Oracle contract for the linked stablecoin.
*   The contract uses the decentralized oracle chainlink
**/

pragma solidity ^0.5.0;

import "./LinkedIORCL.sol";

contract LinkedORCL {

    IEXC public Exchange;
    uint256 public currentPrice;
    address public owner;
    
    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    //constructor
    constructor(address exchangeContractAddr) public {
        owner = msg.sender;
        Exchange = IEXC(exchangeContractAddr);
    }
    
    
    /**
    * @dev Manualy update the contract to check the exchange contract
    */
    function UpdateRate(uint newRate) onlyOwner public {
        assert(Exchange.updateRate(newRate));
    }
    
    
    
     /**
    * @dev Add new implementation for Link based on the SAI Oracle.
    * 
    * DAI oracle because it is cheap (handeld by DAI) and already
    * available on chain. 
    */
    
}