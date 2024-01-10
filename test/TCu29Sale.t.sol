// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import "../src/TCu29Sale.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {ERC20BurnableMock} from "./mocks/ERC20BurnableMock.sol";
import {CzusdGateMock} from "./mocks/CzusdGateMock.sol";

contract TCu29SaleTest is Test {
    TCu29Sale public sale;

    address[] public users;

    ERC20BurnableMock czusd;
    ERC20Mock usdt;
    ERC20Mock tcu29;

    function setUp() public {
        sale = new TCu29Sale(address(this));
        users.push(makeAddr("user0"));
        users.push(makeAddr("user1"));
        users.push(makeAddr("user2"));
        users.push(makeAddr("user3"));

        czusd = new ERC20BurnableMock();
        usdt = new ERC20Mock();
        tcu29 = new ERC20Mock();

        sale.grantRole(sale.MANAGER_ROLE(), users[0]);
        vm.startPrank(users[0]);
        sale.managerUnpause();
        sale.managerSetPrice(2500);
        vm.stopPrank();

        sale.adminSetCzusd(czusd);
        sale.adminSetUsdt(usdt);
        sale.adminSetTcu29(tcu29);
        sale.adminSetCzusdGate(new CzusdGateMock(czusd, usdt));
    }

    function testBuyTCu29Czusd() public {
        tcu29.mint(address(sale), 1_000 ether);
        czusd.mint(users[1], 1_000 ether);

        vm.startPrank(users[1]);
        czusd.approve(address(sale), type(uint256).max);
        sale.buyTCu29Czusd(2.5 ether, users[2]);
        sale.buyTCu29Czusd(10 ether, users[3]);
        vm.stopPrank();

        assertEq(tcu29.balanceOf(users[2]), 1 ether);
        assertEq(tcu29.balanceOf(users[3]), 4 ether);
        assertEq(czusd.balanceOf(users[1]), 1_000 ether - 2.5 ether - 10 ether);
    }

    function testBuyTCu29Usdt() public {
        tcu29.mint(address(sale), 1_000 ether);
        usdt.mint(users[1], 1_000 ether);

        vm.startPrank(users[1]);
        usdt.approve(address(sale), type(uint256).max);
        sale.buyTCu29Usdt(2.5 ether, users[2]);
        sale.buyTCu29Usdt(10 ether, users[3]);
        vm.stopPrank();

        assertEq(tcu29.balanceOf(users[2]), 1 ether);
        assertEq(tcu29.balanceOf(users[3]), 4 ether);
        assertEq(usdt.balanceOf(users[1]), 1_000 ether - 2.5 ether - 10 ether);
    }
}
