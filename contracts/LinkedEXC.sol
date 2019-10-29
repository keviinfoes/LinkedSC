/** Exchange contract for the linked stablecoin.
 *
 *  This is the only accepted exchange between ETH and the stablecoin. The exchange
 *  takes the oracle price input for ETH in USD. Then fixes the price between the
 *  stablecoin and Ether on 1 stablecoin for 1 USD (in ETH)
 *
 * TODO - ADD MATCHING ON CONTRACT FUNDS + ADD BUYER / SEND CHANGE BACK ON MATCHING
 *
 */

 pragma solidity ^0.4.24;

 contract LinkedEXC {
    using SafeMath for uint256;

    IERC20 public token;
    address public owner;
    uint public rate = 200; // Initial rare -> adjusts based on oracle input
    address public oraclecontract;

    //Orderbook - First in first out [FIFO] principle
    struct Buys {
        address buyer;
        uint amount;
        uint minimum;
        uint maximum;
        uint deposit;
        bool closed;
    }
    struct Sells {
        address seller;
        uint amount;
        uint minimum;
        uint maximum;
        bool closed;
    }
    uint256 public indexBuys;
    uint256 public indexSells;
    mapping (uint => Buys) public buyOrders;
    mapping (uint => Sells) public sellOrders;
    mapping (uint => address) public Pendingbuy;
    mapping (uint => address) public Pendingsell;
    uint[] pendingBuy;
    uint[] pendingSell;

    event BuyOrderToken(address user, uint amount, uint costWei, uint balance, uint minimum, uint maximum);
    event SellOrderToken(address user, uint amount, uint costWei, uint balance, uint minimum, uint maximum);
    event OrderMatched(address tokenreceiver, address ethreceiver, uint tokens, uint eth);
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
    * Sender requests to buy [amount] of tokens from the contract.
    * Sender needs to send enough ether to buy the tokens at a price of amount / rate
    */
    function addBuyOrder(uint amount, uint minimum, uint maximum) payable public returns (bool success) {
        //Check ETH funds enough for the requested tokens
        uint costWei = (amount * 1 ether) / rate;
        require(msg.value >= costWei);
        require(costWei >= minimum && costWei <= maximum);
        //Add to orderbook
        buyOrders[indexBuys]= Buys({
            buyer: msg.sender,
            amount: amount,
            minimum: minimum,
            maximum: maximum,
            deposit: msg.value,
            closed: false
        });
        Pendingbuy[indexBuys] = msg.sender;
        indexBuys += 1;
        pendingBuy.push(indexBuys);

        emit BuyOrderToken(msg.sender, amount, costWei, token.balanceOf(msg.sender), minimum, maximum);

        //Check matchingorders
        matchingOrdersBuy(indexBuys);
        return true;
    }

    /**
    *  Sender requests to sell [amount] of tokens
    */
    function addSellOrder(uint amount, uint minimum, uint maximum) public returns (bool success) {
        //Check token funds and send tokens to this contract
        uint costWei = (amount * 1 ether) / rate;
        require(token.balanceOf(msg.sender) >= amount);
        require(costWei >= minimum && costWei <= maximum );
        assert(token.transferFrom(msg.sender, this, amount));
        //Add to orderbook
        sellOrders[indexSells] = Sells({
            seller: msg.sender,
            amount: amount,
            minimum: minimum,
            maximum: maximum,
            closed: false
        });
        Pendingsell[indexSells] = msg.sender;
        indexSells += 1;
        pendingSell.push(indexSells);
        emit SellOrderToken(msg.sender, amount, costWei, token.balanceOf(msg.sender), minimum, maximum);

        matchingOrdersSell(indexSells);
        return true;
    }

    /**
    *  Matching function buy orders - when a match is found with an order it is executed
    */
    function matchingOrdersBuy(uint index) internal returns (bool success) {
        address token_receiver = Pendingbuy[index];
        uint amount = buyOrders[index].amount;
        require(buyOrders[index].closed == false);

        // while loop for matching orders
        uint counter = pendingSell.length;
        uint ETH = (amount * 1 ether) / rate;
        while(counter >= 0){
            uint x = 0;
            if( ETH >= sellOrders[pendingSell[x]].minimum &&
                ETH <= sellOrders[pendingSell[x]].maximum &&
                sellOrders[pendingSell[x]].closed == false) {

                address seller = sellOrders[pendingSell[x]].seller;
                sellOrders[pendingSell[x]].closed = true;

                //Adjust pending sell array
                for (uint i = x; i < pendingSell.length; i++) {
                    pendingSell[i] = pendingSell[i+1];
                }
                delete pendingSell[pendingSell[pendingSell.length - 1]];
                pendingSell.length--;

                //Send tokens to buyer and seller
                assert(token.transfer(token_receiver, amount));
                seller.transfer(amount);
                emit OrderMatched(token_receiver, seller, amount, ETH);
                break;
            }
            x += 1;
            counter = counter - 1;
        }
        matchingContract();
        return true;
    }

     /**
    *  Matching function sell order - when a match is found with an order it is executed
    */
    function matchingOrdersSell(uint index) internal returns (bool success) {
        address ETH_receiver = Pendingsell[index];
        uint amount = sellOrders[index].amount;
        require(sellOrders[index].closed == false);

        // while loop for matching orders
        uint counter = pendingBuy.length;
        uint ETH = (amount * 1 ether) / rate;
        while(counter >= 0){
            uint x = 0;
            if( ETH >= buyOrders[pendingBuy[x]].minimum &&
                ETH <= buyOrders[pendingBuy[x]].maximum &&
                buyOrders[pendingBuy[x]].closed == false) {

                    address buyer = buyOrders[pendingBuy[x]].buyer;
                    buyOrders[pendingBuy[x]].closed = true;

                    //Adjust pending sell array
                    for (uint i = x; i < pendingBuy.length; i++) {
                        pendingBuy[i] = pendingBuy[i+1];
                    }
                    delete pendingBuy[pendingBuy[pendingBuy.length - 1]];
                    pendingBuy.length--;

                    //Send tokens to buyer and seller
                    assert(token.transfer(buyer, amount));
                    buyer.transfer(amount);
                    emit OrderMatched(buyer, ETH_receiver, amount, ETH);
                    //Break the while loop
                    break;
            }
            x += 1;
            counter = counter - 1;
        }
        matchingContract();
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

        //matchtingContract();
        return true;
    }

    /**
    *  cancel buy order function
    */
    function cancelBuyOrder(uint index) public returns (bool success) {
        require (buyOrders[index].closed == false);
        require (buyOrders[index].buyer == msg.sender);
        buyOrders[index].closed = true;
        msg.sender.transfer(buyOrders[index].deposit);
        return true;
    }

    /**
    *  cancel sell order function
    */
    function cancelSellOrder(uint index) public returns (bool success) {
        require (sellOrders[index].closed == false);
        require (sellOrders[index].seller == msg.sender);
        buyOrders[index].closed = true;
        assert(token.transfer(msg.sender, sellOrders[index].amount));
        return true;
    }



    /** TODO - CREATE MATCHING FUNCTION IF THERE ARE FUNDS IN THE CONTRACT
    *  Matching function for when there are no matchable orders in the contract.
    *  The contract owns Tokens and ETH based on the fee in the token contract.
    *  This is to create automated buy / sell pressure for 1 USD per token.
    *
    *  The more the token is used, the more dept the contract has for the stabilisation
    *  of the token (sell/buy for 1 USD).
    */
    function matchingContract() internal returns (bool success) {

        //assert(token.transfer(msg.sender, amount));
        //seller.transfer(amount);
        return true;
    }
}
