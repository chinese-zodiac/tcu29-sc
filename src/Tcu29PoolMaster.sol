// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity ^0.8.23;

import {AccessControlEnumerable} from "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Tcu29Pool} from "./Tcu29Pool.sol";
import {Tcu29PoolStakeWrapperToken} from "./Tcu29PoolStakeWrapperToken.sol";
import "./lib/IterableArrayWithoutDuplicateKeys.sol";

//import "hardhat/console.sol";

contract Tcu29PoolMaster is AccessControlEnumerable {
    using IterableArrayWithoutDuplicateKeys for IterableArrayWithoutDuplicateKeys.Map;
    using SafeERC20 for IERC20;
    using Strings for uint256;

    uint256 public lastDistribution;
    uint256 public distributionPeriod = 3 days;

    bytes32 public constant MANAGER_POOLS = keccak256("MANAGER_POOLS");

    IERC20 public czusd = IERC20(0xE68b79e51bf826534Ff37AA9CeE71a3842ee9c70);
    IERC20 public tcu29CzusdLp =
        IERC20(0x52950E1043A708483988B935F053518C6cD1dF6c);

    IterableArrayWithoutDuplicateKeys.Map tcu29Pools;
    mapping(address pool => uint256 weight) public weights;
    uint256 public totalWeight;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function isDistributeReady() public view returns (bool) {
        return
            (czusd.balanceOf(address(this)) >= 1 ether) &&
            (block.timestamp - lastDistribution >= distributionPeriod);
    }

    function distribute() external {
        require(isDistributeReady());
        uint256 czusdWad = czusd.balanceOf(address(this));
        for (uint256 i = 0; i < tcu29Pools.size(); i++) {
            address pool = tcu29Pools.getKeyAtIndex(i);
            if (weights[pool] != 0) {
                uint256 rewardsWad = (czusdWad * weights[pool]) / totalWeight;
                czusd.approve(pool, rewardsWad);
                Tcu29Pool(pool).addRewardsWithCzusd(rewardsWad);
            }
        }
    }

    function setDistributionPeriod(uint _to) external onlyRole(MANAGER_POOLS) {
        distributionPeriod = _to;
    }

    function addRewardsWithCzusd(uint256 _czusdWad) external {
        czusd.transferFrom(msg.sender, address(this), _czusdWad);
    }

    function getIsTcu29Pool(address _address) public view returns (bool) {
        return tcu29Pools.getIndexOfKey(_address) != -1;
    }

    function getTcu29PoolAddress(uint256 _pid) public view returns (address) {
        return tcu29Pools.getKeyAtIndex(_pid);
    }

    function getTcu29PoolCount() public view returns (uint256) {
        return tcu29Pools.size();
    }

    function addTcu29Pool(
        IERC20Metadata _tribeToken,
        bool _isLrtWhitelist,
        uint256 _weight,
        address _owner
    ) public onlyRole(MANAGER_POOLS) {
        string memory poolWrapperName = string(
            abi.encodePacked(
                "wTcu29Lp-",
                tcu29Pools.size().toString(),
                "-",
                _tribeToken.symbol()
            )
        );
        Tcu29PoolStakeWrapperToken poolWrapper = new Tcu29PoolStakeWrapperToken(
            poolWrapperName, //string memory _name,
            poolWrapperName, //string memory _symbol,
            address(tcu29CzusdLp), //address _underlying,
            address(_tribeToken), //address _tribeToken,
            _isLrtWhitelist, //bool _isLrtWhitelist
            _owner,
            address(this)
        );
        address newPool = address(poolWrapper.pool());
        tcu29Pools.add(newPool);
        weights[newPool] = _weight;
        totalWeight += _weight;
    }

    function removeTcu29Pool(address _pool) external onlyRole(MANAGER_POOLS) {
        totalWeight -= weights[_pool];
        weights[_pool] = 0;
        tcu29Pools.remove(_pool);
    }

    function setTcu29PoolWeight(
        address _pool,
        uint256 _weight
    ) public onlyRole(MANAGER_POOLS) {
        require(getIsTcu29Pool(_pool) == true);
        totalWeight -= weights[_pool];
        weights[_pool] = _weight;
        totalWeight += _weight;
    }

    /**
     * @notice It allows the admin to recover wrong tokens sent to the contract
     * @param _tokenAddress: the address of the token to withdraw
     * @param _tokenAmount: the number of tokens to withdraw
     * @dev This function is only callable by admin.
     */
    function recoverWrongTokens(
        address _tokenAddress,
        uint256 _tokenAmount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC20(_tokenAddress).safeTransfer(address(msg.sender), _tokenAmount);
    }
}
