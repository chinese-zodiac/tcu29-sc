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
        users.push(makeAddr("user4"));

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
        assertEq(sale.totalTcu29Sold(), 5 ether);
        assertEq(sale.totalCzusdDistributed(), 0 ether);
        uint256 expectedBurn = (12.5 ether * 750) / 10000;
        assertEq(expectedBurn, 0.9375 ether);
        assertEq(sale.totalCzusdBurned(), expectedBurn);
        assertEq(
            czusd.balanceOf(address(sale)),
            10 ether + 2.5 ether - expectedBurn
        );
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
        assertEq(sale.totalTcu29Sold(), 5 ether);
        assertEq(sale.totalCzusdDistributed(), 0 ether);
        uint256 expectedBurn = (12.5 ether * 750) / 10000;
        assertEq(expectedBurn, 0.9375 ether);
        assertEq(sale.totalCzusdBurned(), expectedBurn);
        assertEq(
            czusd.balanceOf(address(sale)),
            10 ether + 2.5 ether - expectedBurn
        );
    }

    function testSaleRecipients() public {
        vm.startPrank(users[0]);
        sale.managerSaleRecipientAdd(users[1], 100);
        sale.managerSaleRecipientAdd(users[2], 100);
        sale.managerSaleRecipientAdd(users[3], 100);
        sale.managerSaleRecipientDelete(users[2]);
        sale.managerSaleRecipientAdd(users[4], 300);
        sale.managerSaleRecipientSet(users[3], 50);
        vm.stopPrank();

        assertEq(sale.saleRecipientWeightTotal(), 450);
        assertEq(sale.saleRecipientWeight(users[1]), 100);
        assertEq(sale.saleRecipientWeight(users[2]), 0);
        assertEq(sale.saleRecipientWeight(users[3]), 50);
        assertEq(sale.saleRecipientWeight(users[4]), 300);
        assertEq(sale.saleRecipientsCount(), 3);

        tcu29.mint(address(sale), 1_000 ether);
        czusd.mint(users[0], 1_000 ether);

        vm.startPrank(users[0]);
        czusd.approve(address(sale), type(uint256).max);
        sale.buyTCu29Czusd(2.5 ether, users[2]);
        sale.buyTCu29Czusd(10 ether, users[3]);
        vm.stopPrank();

        uint256 expectedToDistribute = czusd.balanceOf(address(sale));

        vm.prank(users[0]);
        sale.managerDistributeCzusd();

        assertEq(sale.totalCzusdDistributed(), 12.5 ether - 0.9375 ether - 1);
        assertEq(sale.totalCzusdDistributed(), expectedToDistribute - 1);

        assertEq(czusd.balanceOf(users[1]), (expectedToDistribute * 100) / 450);
        assertEq(czusd.balanceOf(users[2]), 0);
        assertEq(czusd.balanceOf(users[3]), (expectedToDistribute * 50) / 450);
        assertEq(czusd.balanceOf(users[4]), (expectedToDistribute * 300) / 450);
    }
}
