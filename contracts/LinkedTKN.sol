/** Stable coin - named LINKED [LKD]
*   Linked is a non-custodial stable coin with the goal of simplifying the implementation
*   before Linked, non-custodial stable coins are complex [copied from the fiat central banks]
*   using bonds and other implementation to stabelize the system.
*
*	  Linked is stable because it simply limits where you can exchange it for ETH. The address of
*   the only exchange is fixed in the token contract.
**/

pragma solidity ^0.4.24;

import "@openzeppelin/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";
import "@openzeppelin/contracts/access/roles/MinterRole.sol";

contract LinkedTKN is IERC20, ERC20Detailed, Ownable, MinterRole {
	using SafeMath for uint256;

  address public exchangeContract;
	mapping (address => uint256) private _balances;
	mapping (address => mapping (address => uint256)) private _allowances;
	uint256 private _totalSupply;

	uint256 public _feeTokens;
	uint256 public _feeETH;

  /**
  * @dev Throws if called by contract other than the DEX.
  */
  modifier onlyUsers() {
      require(checkUser(msg.sender) == false || msg.sender == exchangeContract);
      _;
  }

	/**
	* @dev See `IERC20.totalSupply`.
	*/
	function totalSupply() public view returns (uint256) {
			return _totalSupply;
	}

	/**
	* @dev See `IERC20.balanceOf`.
	*/
	function balanceOf(address account) onlyUsers public view returns (uint256) {
			return _balances[account];
	}

	/**
  * Set exchange address
  */
  function changeExchangeAddress(address ExchangeAddress) onlyOwner public returns (bool success) {
      require (ExchangeAddress != address(0));
      exchangeContract = ExchangeAddress;
      return true;
  }

  /**
  * @dev Check if the address it interacts with is a user.
  *
  * Note that if this function is called from the constructor of a new contract
  * it says its not a contract.
  *
  * This not a issue because this is a very limited action, not feasible to
  * build a DEX on.
  *
  */
  function checkUser(address _addr) view private returns (bool isContract) {
      uint32 size;
      assembly {
          size := extcodesize(_addr)
      }
  return (size > 0);
  }

	/**
	* @dev See `IERC20.transfer`.
	*
	* Requirements:
	*
	* - `recipient` cannot be the zero address.
	* - the caller must have a balance of at least `amount`.
	*/
	function transfer(address recipient, uint256 amount) onlyUsers public payable returns (bool) {
			_transfer(msg.sender, recipient, amount);
			return true;
	}

	/**
	* @dev See `IERC20.allowance`.
	*/
	function allowance(address owner, address spender) onlyUsers public view returns (uint256) {
			return _allowances[owner][spender];
	}

	/**
	* @dev See `IERC20.approve`.
	*
	* Requirements:
	*
	* - `spender` cannot be the zero address.
	*/
	function approve(address spender, uint256 value) onlyUsers public returns (bool) {
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
	function transferFrom(address sender, address recipient, uint256 amount) onlyUsers public returns (bool) {
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
	function increaseAllowance(address spender, uint256 addedValue) onlyUsers public returns (bool) {
			_approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
			return true;
	}

	/**
	* @dev Atomically decreases the allowance granted to `spender` by the caller.
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
	function decreaseAllowance(address spender, uint256 subtractedValue) onlyUsers public returns (bool) {
			_approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
			return true;
	}

	/**
	* @dev Mint functions - for dev purpose controlled by Minter
  **/
  function mint(address account, uint256 amount) public onlyMinter returns (bool) {
      _feeTokens = 1;
      _feeETH = 1 * 1 finney;
      _mint(account, amount);
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
			uint256 amount_minusfee = amount - _feeTokens;
			uint256 ETH_minusfee = msg.value - _feeETH;
			_balances[sender] = _balances[sender].sub(amount);
			_balances[exchangeContract] = _balances[exchangeContract].add(_feeTokens);
			_balances[recipient] = _balances[recipient].add(amount_minusfee);
			exchangeContract.transfer(_feeETH);
			msg.sender.transfer(ETH_minusfee);
			emit Transfer(sender, recipient, amount, _feeTokens, _feeETH);
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

			_totalSupply = _totalSupply.add(amount);
			_balances[account] = _balances[account].add(amount);
			emit Transfer(address(0), account, amount, _feeTokens, _feeETH);
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

			_totalSupply = _totalSupply.sub(value);
			_balances[account] = _balances[account].sub(value);
			emit Transfer(account, address(0), value, _feeTokens, _feeETH);
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
	* @dev Destoys `amount` tokens from `account`.`amount` is then deducted
	* from the caller's allowance.
	*
	* See `_burn` and `_approve`.
	*/
	function _burnFrom(address account, uint256 amount) internal {
			_burn(account, amount);
			_approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
	}
}
