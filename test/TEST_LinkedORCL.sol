pragma solidity ^0.4.24;

/**
 * @dev Interface of the Exchange contract
 * for testing purposes.
 *
 */
interface IEXC {

    function updateRate(uint newRate) external returns (bool success);
}


/**
 *  Test oracle contract
 *
**/
contract TestLinkedORCL {

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

}
