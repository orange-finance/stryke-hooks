// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {IV2Hooks} from "./IV2Hooks.sol";
import {IV2Handler, TokenIdInfo, PositionUseData} from "./IV2Handler.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract UtilizationLimitHooks is IV2Hooks, Ownable(msg.sender) {
    error UtilizationLimitHooks__NotImplemented();
    error UtilizationLimitHooks__UtilizationLimitExceeded(uint256 expected, uint256 actual);
    error UtilizationLimitHooks__InvalidUtilizationLimit(uint256 limit);

    uint256 internal constant MAX_UTILIZATION_RATE = 1e36;
    uint256 public utilizationLimit = MAX_UTILIZATION_RATE;

    function setUtilizationLimit(uint256 newLimit) external onlyOwner {
        require(newLimit <= MAX_UTILIZATION_RATE, UtilizationLimitHooks__InvalidUtilizationLimit(newLimit));
        utilizationLimit = newLimit;
    }

    function onPositionUse(bytes calldata data) external view {
        PositionUseData memory decoded = abi.decode(data, (PositionUseData));
        uint256 tokenId = uint256(
            keccak256(abi.encode(msg.sender, decoded.pool, address(this), decoded.tickLower, decoded.tickUpper))
        );
        TokenIdInfo memory td = IV2Handler(msg.sender).tokenIds(tokenId);

        // TODO: Consider the liquidity to use on current context
        uint256 rate = Math.mulDiv(td.liquidityUsed, MAX_UTILIZATION_RATE, td.totalLiquidity + td.reservedLiquidity);
        require(rate <= utilizationLimit, UtilizationLimitHooks__UtilizationLimitExceeded(utilizationLimit, rate));
    }

    function onPositionUnUse(bytes calldata) external pure {
        revert UtilizationLimitHooks__NotImplemented();
    }
}
