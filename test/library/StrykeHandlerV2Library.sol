// SPDX-License-Identifier: MIT

pragma solidity 0.8.27;

import {IV2Handler, TokenIdInfo, PositionUseData} from "../../src/IV2Handler.sol";
import {Vm} from "forge-std/Vm.sol";

struct MintPositionParams {
    address pool;
    address hook;
    int24 tickLower;
    int24 tickUpper;
    uint128 liquidity;
}

struct UsePositionParams {
    address pool;
    address hook;
    int24 tickLower;
    int24 tickUpper;
    uint128 liquidityToUse;
}

struct ReserveLiquidityParams {
    address pool;
    address hook;
    int24 tickLower;
    int24 tickUpper;
    uint128 liquidity;
}

interface IV2HandlerExtended {
    function convertToShares(uint128 assets, uint256 tokenId) external view returns (uint256);

    function updateWhitelistedApps(address app, bool whitelisted) external;

    function mintPositionHandler(address context, bytes calldata data) external;

    function usePositionHandler(bytes calldata data) external;

    function reserveLiquidity(bytes calldata data) external;
}

library StrykeHandlerV2Library {
    // solhint-disable-next-line const-name-snakecase
    Vm private constant vm = Vm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    function tokenId(
        address handler,
        address pool,
        address hook,
        int24 tickLower,
        int24 tickUpper
    ) internal pure returns (uint256) {
        return uint256(keccak256(abi.encode(handler, pool, hook, tickLower, tickUpper)));
    }

    function tokenIds(
        address handler,
        address pool,
        address hook,
        int24 tickLower,
        int24 tickUpper
    ) internal view returns (TokenIdInfo memory) {
        return IV2Handler(handler).tokenIds(tokenId(handler, pool, hook, tickLower, tickUpper));
    }

    function updateWhitelistedApps(address handler, address app, bool whitelisted) internal {
        IV2HandlerExtended(handler).updateWhitelistedApps(app, whitelisted);
    }

    function mintPosition(address handler, address context, MintPositionParams memory params, address caller) internal {
        vm.prank(caller);
        IV2HandlerExtended(handler).mintPositionHandler(context, abi.encode(params));
    }

    function usePosition(address handler, UsePositionParams memory params, address caller) internal {
        vm.prank(caller);
        IV2HandlerExtended(handler).usePositionHandler(
            abi.encode(
                params,
                abi.encode(
                    PositionUseData({
                        app: caller,
                        ttl: 0, // dummy
                        isCall: false, // dummy
                        pool: params.pool,
                        tickLower: params.tickLower,
                        tickUpper: params.tickUpper
                    })
                )
            )
        );
    }

    function reserveLiquidity(address handler, ReserveLiquidityParams memory params, address caller) internal {
        uint256 shares = IV2HandlerExtended(handler).convertToShares(
            params.liquidity,
            tokenId(handler, params.pool, params.hook, params.tickLower, params.tickUpper)
        );
        params.liquidity = uint128(shares);
        vm.prank(caller);
        IV2HandlerExtended(handler).reserveLiquidity(abi.encode(params));
    }
}
