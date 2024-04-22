// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {TCu29Sale} from "./TCu29Sale.sol";
import {TokenTimelock} from "./TokenTimelock.sol";

contract TCu29SaleVesting is TCu29Sale {
    TokenTimelock public timeLock;

    constructor(
        address admin,
        address beneficiary,
        uint64 releaseEpoch
    ) TCu29Sale(admin) {
        saleBurnBasis = 12;
        timeLock = new TokenTimelock(IERC20(tcu29), beneficiary, releaseEpoch);
    }
}
