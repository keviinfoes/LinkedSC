/** 
 * Custodian contract for the linked stablecoin.
 * 
 */

pragma solidity ^0.5.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LinkedCUS {
    using SafeMath for uint256;
    
    IERC20 public token;
    address public owner;

    mapping (address => bool) private exchanges; 
    
    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyExchange() {
        require(exchanges[msg.sender], "Exchange not whitelisted");
        _;
    }
    
    /**
    * constructor
    */
    constructor() public {
        owner = msg.sender;
    }
    
    /**
    * @dev function. Used to load the exchange with ether
    */
    function() external payable {}
    
    /**
    * @dev add exchanges to the custodian contract. 
    */
    function addExchange(address exchange) onlyOwner public returns (bool success) {
        require (exchange != address(0));
        exchanges[exchange] = true;
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
    * @dev mint new tokens or burn tokens for the buy/sell of the exchanges
    */
    function mint(address receiver, uint256 amount) onlyExchange public returns (bool success) {
        token.mint(receiver, amount);
        return true;
    }
    function burn(address burner, uint256 amount) onlyExchange public returns (bool success) {
        token.burn(burner, amount);
        return true;
    }
    
    /**
    * @dev transfer function for ETH send by exchanges
    */
    function transfer(address payable receiver, uint256 amount) onlyExchange public returns (bool success) {
        receiver.transfer(amount);
        return true;
    }
    
    /**
    * @dev checkif exchange is whitelisted
    */
    function checkExchange(address exchange) public view returns (bool success) {
        return exchanges[exchange];
    }  
}