pragma solidity ^0.4.24;

/**
 * @dev Interface of the Exchange contract
 * for testing purposes.
 *
 */
interface IEXC {

    function updateRate(uint newRate) external returns (bool success);
}
