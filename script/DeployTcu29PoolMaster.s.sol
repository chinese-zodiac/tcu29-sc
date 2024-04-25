// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import "forge-std/Script.sol";
import "../src/Tcu29PoolMaster.sol";

contract DeployTcu29PoolMaster is Script {
    address admin = address(0x745A676C5c472b50B50e18D4b59e9AeEEc597046);
    address manager = address(0xfcD9F2d36f7315d2785BA19ca920B14116EA3451);

    function run() public {
        vm.startBroadcast();

        //DO NOT DEPLOY NEW PNSH/USDT CONTRACT IF ONE IS ALREADY ON THE NETWORK (COMMENT OUT)
        new Tcu29PoolMaster(admin, manager);

        vm.stopBroadcast();
    }
}
