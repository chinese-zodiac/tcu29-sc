// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import "forge-std/Script.sol";
import "../src/TCu29Sale.sol";

contract DeployTCu29Sale is Script {
    address admin = address(0x745A676C5c472b50B50e18D4b59e9AeEEc597046);

    function run() public {
        vm.startBroadcast();

        //DO NOT DEPLOY NEW PNSH/USDT CONTRACT IF ONE IS ALREADY ON THE NETWORK (COMMENT OUT)
        new TCu29Sale(admin);

        vm.stopBroadcast();
    }
}
