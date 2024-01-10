// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {AccessControlEnumerable} from "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";
import {IterableArrayWithoutDuplicateKeys} from "./lib/IterableArrayWithoutDuplicateKeys.sol";
import {ICzusdGate} from "./interfaces/ICzusdGate.sol";

contract TCu29Sale is AccessControlEnumerable, Pausable {
    using IterableArrayWithoutDuplicateKeys for IterableArrayWithoutDuplicateKeys.Map;
    using SafeERC20 for IERC20;

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    IERC20 public czusd = IERC20(0xE68b79e51bf826534Ff37AA9CeE71a3842ee9c70);
    IERC20 public usdt = IERC20(0x55d398326f99059fF775485246999027B3197955);
    IERC20 public tcu29 = IERC20(0x8fEEdfcdd4264EA97d1656F20E162D8336926482);
    ICzusdGate public czusdGate =
        ICzusdGate(0xeB7aaB426902A59722D1EC22314d770b1aEBFeBC);

    IterableArrayWithoutDuplicateKeys.Map private saleRecipients;
    mapping(address recipient => uint32 weight) public saleRecipientWeight;
    uint32 public saleRecipientWeightTotal;
    uint32 public saleBurnBasis = 750;

    uint256 public totalCzusdDistributed;
    uint256 public totalTcu29Sold;

    uint32 public price = 4200; //Price in thousandths (eg: 8346 = 8.346 means 1 TCu29 = 8.346 CZUSD)

    //Sanity limits to prevent fat finger errors
    uint32 public priceMin = 1000; //$1.000
    uint32 public priceMax = 20000; //$20.000

    //Cap per tx
    uint256 public buyCap = 10_000 ether;

    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _pause();
    }

    function buyTCu29Usdt(
        uint256 amtUsdt,
        address recipient
    ) external whenNotPaused {
        require(amtUsdt <= buyCap, "Cannot exceed buyCap");
        uint256 initialCzusdBal = czusd.balanceOf(address(this));
        usdt.safeTransferFrom(msg.sender, address(this), amtUsdt);
        usdt.approve(address(czusdGate), amtUsdt);
        czusdGate.usdtIn(amtUsdt, address(this));
        uint256 czusdReceived = czusd.balanceOf(address(this)) -
            initialCzusdBal;
        uint256 tcu29Purchased = (czusdReceived * 1000) / price;
        tcu29.safeTransfer(recipient, tcu29Purchased);
        totalCzusdDistributed += czusdReceived;
        totalTcu29Sold += tcu29Purchased;
    }

    function buyTCu29Czusd(
        uint256 amtCzusd,
        address recipient
    ) external whenNotPaused {
        require(amtCzusd <= buyCap, "Cannot exceed buyCap");
        uint256 initialCzusdBal = czusd.balanceOf(address(this));
        czusd.safeTransferFrom(msg.sender, address(this), amtCzusd);
        uint256 czusdReceived = czusd.balanceOf(address(this)) -
            initialCzusdBal;
        uint256 tcu29Purchased = (czusdReceived * 1000) / price;
        tcu29.safeTransfer(recipient, tcu29Purchased);
        totalCzusdDistributed += czusdReceived;
        totalTcu29Sold += tcu29Purchased;
    }

    function managerTcu29Deposit(uint256 amt) external onlyRole(MANAGER_ROLE) {
        tcu29.safeTransferFrom(msg.sender, address(this), amt);
    }

    function managerTcu29Withdraw(uint256 amt) external onlyRole(MANAGER_ROLE) {
        tcu29.safeTransfer(msg.sender, amt);
    }

    function managerSaleRecipientDelete(
        address recipient
    ) external onlyRole(MANAGER_ROLE) {
        require(
            saleRecipients.has(recipient),
            "Recipient not in saleRecipients"
        );
        saleRecipients.remove(recipient);
        saleRecipientWeightTotal -= saleRecipientWeight[recipient];
        delete saleRecipientWeight[recipient];
    }

    function managerSaleRecipientSet(
        address recipient,
        uint32 weight
    ) external onlyRole(MANAGER_ROLE) {
        require(
            saleRecipients.has(recipient),
            "Recipient not in saleRecipients"
        );
        saleRecipientWeightTotal -= saleRecipientWeight[recipient];
        saleRecipientWeight[recipient] = weight;
        saleRecipientWeightTotal += weight;
    }

    function managerSaleRecipientAdd(
        address recipient,
        uint32 weight
    ) external onlyRole(MANAGER_ROLE) {
        require(!saleRecipients.has(recipient), "Recipient in saleRecipients");
        saleRecipients.add(recipient);
        saleRecipientWeight[recipient] = weight;
        saleRecipientWeightTotal += weight;
    }

    function managerDistributeCzusd() external onlyRole(MANAGER_ROLE) {
        uint256 toSend = czusd.balanceOf(address(this));
        uint256 saleRecipientsSize = saleRecipients.size();
        for (uint256 i; i < saleRecipientsSize; i++) {
            address recipient = saleRecipients.getKeyAtIndex(i);
            uint32 weight = saleRecipientWeight[recipient];
            czusd.safeTransfer(
                recipient,
                (weight * toSend) / saleRecipientWeightTotal
            );
        }
    }

    function managerUnpause() external onlyRole(MANAGER_ROLE) {
        _unpause();
    }

    function managerPause() external onlyRole(MANAGER_ROLE) {
        _pause();
    }

    function managerSetPrice(
        uint32 priceThousandths
    ) external onlyRole(MANAGER_ROLE) {
        require(priceThousandths >= priceMin, "Below priceMin");
        require(priceThousandths <= priceMax, "Below priceMax");
        price = priceThousandths;
    }

    function adminSetPriceMinMax(
        uint32 minPriceThousandths,
        uint32 maxPriceThousandths
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        priceMin = minPriceThousandths;
        priceMax = maxPriceThousandths;
    }

    function adminSetBuyCap(uint256 to) external onlyRole(DEFAULT_ADMIN_ROLE) {
        buyCap = to;
    }

    function adminSetCzusd(IERC20 to) external onlyRole(DEFAULT_ADMIN_ROLE) {
        czusd = to;
    }

    function adminSetUsdt(IERC20 to) external onlyRole(DEFAULT_ADMIN_ROLE) {
        usdt = to;
    }

    function adminSetTcu29(IERC20 to) external onlyRole(DEFAULT_ADMIN_ROLE) {
        tcu29 = to;
    }

    function adminSetCzusdGate(
        ICzusdGate to
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        czusdGate = to;
    }

    function adminRecoverERC20(
        address tokenAddress,
        address recipient
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC20(tokenAddress).transfer(
            recipient,
            IERC20(tokenAddress).balanceOf(address(this))
        );
    }

    function saleRecipientsCount() external view returns (uint256) {
        return saleRecipients.size();
    }

    function saleRecipientsAt(uint256 index) external view returns (address) {
        return saleRecipients.getKeyAtIndex(index);
    }
}
