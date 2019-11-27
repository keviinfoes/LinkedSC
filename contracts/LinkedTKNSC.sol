/** 
*   Stable coin - named LINKED [LKD]
*
*   Linked is a non-custodial stable coin with the goal of simplifying the implementation
*   before Linked, non-custodial stable coins use complex implementations.
*   For example by using bonds and other implementation to stabilize the system.
*
*   Linked is stable because it simply imlements a stability tax that ensures the exchange for 
*   the fixed rate of 1 USD.
*   
**/

pragma solidity ^0.5.0;

import "@openzeppelin/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";
import "@openzeppelin/contracts/access/roles/MinterRole.sol";

contract LinkedTKN is IERC20, ERC20Detailed, Ownable, MinterRole {
	using SafeMath for uint256;

    	struct Balance { 
        	uint256 amount;
        	uint256 taxBlock;
    	}
    	struct Tax {
        	uint256 amount;
        	uint256 taxBlock;
    	}

    	//Contract addresses
    	address payable public custodianContract;
    	address payable public taxAuthority;
	//Supply variables
	mapping (address => Balance) private _balances;
	mapping (address => mapping (address => uint256)) private _allowances;
    	uint256 private _totalSupply;
	//Stability tax variables
	Tax private _tax;
	uint256 public _feeETH = 1 finney; 
    	uint256 public _blockTax = 2; // 2%
    	uint256 public _blockYear = 2000000; // ~2 million blocks per year
    
	/**
	 * @dev View supply variables
	 */
	function totalSupply() public view returns (uint256) {
			return _totalSupply;
	}
    
    	/**
    	* Fallback function. Used to load the exchange with ether
    	*/
    	function() external payable {}
    
	/**
	 * @dev show balance of the address.
	 */
	function balanceOf(address account) public view returns (uint256) {
		uint256 blockDelta = block.number.sub(_balances[account].taxBlock);
		uint256 yearAmount = _balances[account].amount.div(100).mul(_blockTax);
		uint256 blockAmount = yearAmount.div(_blockYear);
		uint256 tax = blockDelta.mul(blockAmount);
		uint256 balance = _balances[account].amount.sub(tax);
		return balance;
	}
	
	function taxReserve() public view returns (uint256) {
		uint256 blockDelta = block.number.sub(_tax.taxBlock);
		uint256 yearAmount = _totalSupply.div(100).mul(_blockTax);
		uint256 blockAmount = yearAmount.div(_blockYear);
		uint256 tax = blockDelta.mul(blockAmount);
		uint256 balance = _tax.amount.add(tax);
		return balance;
	}
	
	/**
	 * @dev See `IERC20.transfer`.
	 *
	 * Requirements:
	 *
	 * - `recipient` cannot be the zero address.
	 * - the caller must have a balance of at least `amount`.
	 */
	function transfer(address recipient, uint256 amount) public payable returns (bool) {
			_transfer(msg.sender, recipient, amount);
			return true;
	}

	/**
	 * @dev See `IERC20.allowance`.
	 */
	function allowance(address owner, address spender) public view returns (uint256) {
			return _allowances[owner][spender];
	}

	/**
	 * @dev See `IERC20.approve`.
	 *
	 * Requirements:
	 *
	 * - `spender` cannot be the zero address.
	 */
	function approve(address spender, uint256 value) public returns (bool) {
			_approve(msg.sender, spender, value);
			return true;
	}

	/**
	 * @dev See `IERC20.transferFrom`.
	 *
	 * Emits an `Approval` event indicating the updated allowance. This is not
	 * required by the EIP. See the note at the beginning of `ERC20`;
	 *
	 * Requirements:
	 * - `sender` and `recipient` cannot be the zero address.
	 * - `sender` must have a balance of at least `value`.
	 * - the caller must have allowance for `sender`'s tokens of at least
	 * `amount`.
	 */
	function transferFrom(address sender, address recipient, uint256 amount) public payable returns (bool) {
			_transfer(sender, recipient, amount);
			_approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
			return true;
	}

	/**
	 * @dev Atomically increases the allowance granted to `spender` by the caller.
	 *
	 * This is an alternative to `approve` that can be used as a mitigation for
	 * problems described in `IERC20.approve`.
	 *
	 * Emits an `Approval` event indicating the updated allowance.
	 *
	 * Requirements:
	 *
	 * - `spender` cannot be the zero address.
	 */
	function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
			_approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
			return true;
	}

	/**
	 * @dev Automically decreases the allowance granted to `spender` by the caller.
	 *
	 * This is an alternative to `approve` that can be used as a mitigation for
	 * problems described in `IERC20.approve`.
	 *
	 * Emits an `Approval` event indicating the updated allowance.
	 *
	 * Requirements:
	 *
	 * - `spender` cannot be the zero address.
	 * - `spender` must have allowance for the caller of at least
	 * `subtractedValue`.
	 */
	function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
			_approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
			return true;
	}
	
	/**
	 * @dev Mint and burn functions - controlled by Minter (is custodian)
   	**/
    	function mint(address account, uint256 amount) public onlyMinter returns (bool) {
           		 _mint(account, amount);
            		return true;
    	}
    	function burn(address account, uint256 amount) public onlyMinter returns (bool) {
            		_burn(account, amount);
            		return true;
    	}
    	function tax() public returns (bool) {
            		_taxClaim();
            		return true;
    	}
    
    	/**
   	 * Set contract addresses
    	*/
    	function changeCustodianAddress(address payable custodianAddress) onlyOwner public returns (bool success) {
            		require (custodianAddress != address(0));
            		custodianContract = custodianAddress;
            		addMinter(custodianAddress);
           	 return true;
    	}
    	function changeTaxAddress(address payable taxAddress) onlyOwner public returns (bool success) {
            		require (taxAddress != address(0));
            		taxAuthority = taxAddress;
            		return true;
    	}

	/**
	 * @dev Moves tokens `amount` from `sender` to `recipient`.
	 *
	 * This is internal function is equivalent to `transfer`, and can be used to
	 * e.g. implement automatic token fees, slashing mechanisms, etc.
	 *
	 * Emits a `Transfer` event.
	 *
	 * Requirements:
	 *
	 * - `sender` cannot be the zero address.
	 * - `recipient` cannot be the zero address.
	 * - `sender` must have a balance of at least `amount`.
	 */
	function _transfer(address sender, address recipient, uint256 amount) internal {
			require(sender != address(0), "ERC20: transfer from the zero address");
			require(recipient != address(0), "ERC20: transfer to the zero address");
			require(msg.value >= _feeETH);
			uint256 _changeETH = msg.value.sub(_feeETH);
			//Send stability fee to custodian
			custodianContract.transfer(_feeETH);
			//Set amount to balance minus tax
			_balances[sender].amount = balanceOf(sender);
			//Send transaction
			_balances[sender].amount = _balances[sender].amount.sub(amount);
			_balances[recipient].amount = _balances[recipient].amount.add(amount);
			_balances[sender].taxBlock = block.number;
			_balances[recipient].taxBlock = block.number;
			//Return stability fee change
			msg.sender.transfer(_changeETH);
			emit Transfer(sender, recipient, amount, _feeETH);
	}

	/** @dev Creates `amount` tokens and assigns them to `account`, increasing
	 * the total supply.
	 *
	 * Emits a `Transfer` event with `from` set to the zero address.
	 *
	 * Requirements
	 *
	 * - `to` cannot be the zero address.
	 */
	function _mint(address account, uint256 amount) internal {
			require(account != address(0), "ERC20: mint to the zero address");
			//Set amount to balance minus tax
			_balances[account].amount = balanceOf(account);
			_balances[account].taxBlock = block.number;
			_tax.amount = taxReserve();
			_tax.taxBlock = block.number;
			//Add minted amount
			_totalSupply = _totalSupply.add(amount);
			_balances[account].amount = _balances[account].amount.add(amount);
			
			emit Transfer(address(0), account, amount, 0);
	}

	 /**
	 * @dev Destoys `amount` tokens from `account`, reducing the
	 * total supply.
	 *
	 * Emits a `Transfer` event with `to` set to the zero address.
	 *
	 * Requirements
	 *
	 * - `account` cannot be the zero address.
	 * - `account` must have at least `amount` tokens.
	 */
	function _burn(address account, uint256 value) internal {
			require(account != address(0), "ERC20: burn from the zero address");
			//Set amount to balance minus tax
			_balances[account].amount = balanceOf(account);
			//Remove burned amount
			_balances[account].amount = _balances[account].amount.sub(value);
			_tax.amount = taxReserve();
			_tax.taxBlock = block.number;
			emit Transfer(account, address(0), value, 0);
	}

	/**
	 * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
	 *
	 * This is internal function is equivalent to `approve`, and can be used to
	 * e.g. set automatic allowances for certain subsystems, etc.
	 *
	 * Emits an `Approval` event.
	 *
	 * Requirements:
	 *
	 * - `owner` cannot be the zero address.
	 * - `spender` cannot be the zero address.
	 */
	function _approve(address owner, address spender, uint256 value) internal {
			require(owner != address(0), "ERC20: approve from the zero address");
			require(spender != address(0), "ERC20: approve to the zero address");
			_allowances[owner][spender] = value;
			emit Approval(owner, spender, value);
	}
	
	/**
	 * @dev claim the tax reserve
	 */
	function _taxClaim() internal {
			require(msg.sender == taxAuthority);
			_tax.amount = taxReserve();
			_tax.taxBlock = block.number;
			_balances[taxAuthority].amount.add(_tax.amount);
			_tax.amount = 0;
	}
} 
