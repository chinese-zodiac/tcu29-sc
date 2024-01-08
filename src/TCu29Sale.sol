// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {IterableArrayWithoutDuplicateKeys} from "./lib/IterableArrayWithoutDuplicateKeys.sol";

contract TCu29Sale {
    using IterableArrayWithoutDuplicateKeys for IterableArrayWithoutDuplicateKeys.Map; 
    
    IterableArrayWithoutDuplicateKeys.Map private acceptedStablecoins;
    IterableArrayWithoutDuplicateKeys.Map private saleRecipients;
    mapping(address recipient=>uint256 weight) public saleRecipientWeight;
    uint256 public saleRecipientWeightMax = 9250;

}