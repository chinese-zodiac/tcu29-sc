// SPDX-License-Identifier: GPL-3.0
// OpenZeppelin Contracts
pragma solidity ^0.8.23;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title TokenTimelock
 * @dev TokenTimelock is a token holder contract that will allow a
 * beneficiary to extract the tokens after a given release time
 */
contract TokenTimelock {
    using SafeERC20 for IERC20;

    // ERC20 basic token contract being held
    IERC20 public token;

    // beneficiary of tokens after they are released
    address public beneficiary;

    // timestamp when token release is enabled
    uint64 public releaseTime;

    constructor(IERC20 _token, address _beneficiary, uint64 _releaseTime) {
        require(_releaseTime > block.timestamp);
        token = _token;
        beneficiary = _beneficiary;
        releaseTime = _releaseTime;
    }

    /**
     * @notice Transfers tokens held by timelock to beneficiary.
     * Deprecated: please use TokenTimelock#release instead.
     */
    function claim() public {
        require(msg.sender == beneficiary);
        release();
    }

    /**
     * @notice Transfers tokens held by timelock to beneficiary.
     */
    function release() public {
        require(block.timestamp >= releaseTime);

        uint256 amount = token.balanceOf(address(this));
        require(amount > 0);

        token.safeTransfer(beneficiary, amount);
    }
}
