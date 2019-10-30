/**
*   Oracle contract for the linked stablecoin.
*   The contract uses the decentralized oracle chainlink
**/

pragma solidity ^0.4.24;

import "chainlink/contracts/ChainlinkClient.sol";
import "./LinkedIORCL.sol";

contract LinkedORCL is ChainlinkClient {

    uint256 public currentPrice;
    address public owner;
    IEXC public Exchange;

    //Constructor sets the token address for the LINK token and the owner.
    constructor(address exchangeContractAddr) public {
        setPublicChainlinkToken();
        Exchange = IEXC(exchangeContractAddr);
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    // Creates a Chainlink request with the uint256 multiplier job - for simplicity by the call of
    function requestEthereumPrice(address _oracle, string _jobId, uint256 _payment)
        public
        onlyOwner
    {
        // newRequest takes a JobID, a callback address, and callback function as input
        Chainlink.Request memory req = buildChainlinkRequest(stringToBytes32(_jobId), this, this.fulfill.selector);
        // Adds a URL with the key "get" to the request parameters
        req.add("get", "https://min-api.cryptocompare.com/data/price?fsym=ETH&tsyms=USD");
        // Uses input param (dot-delimited string) as the "path" in the request parameters
        req.add("path", "USD");
        // Adds an integer with the key "times" to the request parameters
        req.addInt("times", 100);
        // Sends the request with the amount of payment specified to the oracle
        sendChainlinkRequestTo(_oracle, req, _payment);
    }

    function stringToBytes32(string memory source) private pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
        assembly { // solhint-disable-line no-inline-assembly
            result := mload(add(source, 32))
        }
    }

    // fulfill receives a uint256 data type
    function fulfill(bytes32 _requestId, uint256 _price)
        public
        // Use recordChainlinkFulfillment to ensure only the requesting oracle can fulfill
        recordChainlinkFulfillment(_requestId)
    {
     currentPrice = _price;
     Exchange.updateRate(_price);
    }

    // withdrawLink allows the owner to withdraw any extra LINK on the contract
    function withdrawLink()
        public
        onlyOwner
    {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(link.transfer(msg.sender, link.balanceOf(address(this))), "Unable to transfer");
    }
}
