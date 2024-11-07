// SPDX-License-Identifier: MIT

/* solhint-disable no-inline-assembly */

pragma solidity 0.8.27;

import {Test} from "forge-std/Test.sol";
import {UtilizationLimitHooks} from "../../src/UtilizationLimitHooks.sol";
import {TokenIdInfo} from "../../src/IV2Handler.sol";
import {IUniswapV3Pool} from "v3-core/interfaces/IUniswapV3Pool.sol";
import {IUniswapV3Factory} from "v3-core/interfaces/IUniswapV3Factory.sol";
import {Math} from "openzeppelin-contracts/contracts/utils/math/Math.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {UniswapV3Library} from "../library/UniswapV3Library.sol";
import {StrykeHandlerV2Library, MintPositionParams, UsePositionParams, ReserveLiquidityParams} from "../library/StrykeHandlerV2Library.sol";

contract UtilizationLimitHooksTest is Test {
    using UniswapV3Library for address;
    using StrykeHandlerV2Library for address;

    UtilizationLimitHooks public hooks;

    address internal uniswapV3Factory;
    address internal uniswapV3Router;
    address internal uniswapV3Pool;
    address internal strykePositionManager;
    address internal strykeHandler;

    address internal token0;
    address internal token1;

    address internal alice = makeAddr("alice");
    address internal bob = makeAddr("bob");
    address internal carol = makeAddr("carol");

    function setUp() public {
        hooks = new UtilizationLimitHooks();
        uniswapV3Factory = deployV3Factory();
        uniswapV3Router = deployV3Router(uniswapV3Factory, address(0));
        strykePositionManager = deployPositionManager();
        strykeHandler = deployHandler(
            uniswapV3Factory,
            vm.readFileBinary("test/bin/uniswapV3Pool.bin"),
            uniswapV3Router
        );
        token0 = address(0x1000);
        token1 = address(0x2000);
        vm.etch(token0, address(deployMockERC20("Token0", "T0", 18)).code);
        vm.etch(token1, address(deployMockERC20("Token1", "T1", 18)).code);

        uniswapV3Pool = IUniswapV3Factory(uniswapV3Factory).createPool(token0, token1, 500);
        // 1 Token0 ≈ 2000 Token1
        IUniswapV3Pool(uniswapV3Pool).initialize(3543191142285914205922034);

        strykeHandler.updateWhitelistedApps(address(this), true);
    }

    function test_When_utilizationLimitNotExceeded() public {
        hooks.setUtilizationLimit(0.5e36);
        uint128 liquidity = mint(-200330, -200320, 100e18, alice);
        TokenIdInfo memory info = StrykeHandlerV2Library.tokenIds(
            strykeHandler,
            uniswapV3Pool,
            address(hooks),
            -200330,
            -200320
        );
        assertEq(info.totalLiquidity, liquidity);
        use(-200330, -200320, liquidity / 2, bob);

        info = StrykeHandlerV2Library.tokenIds(strykeHandler, uniswapV3Pool, address(hooks), -200330, -200320);
        assertEq(info.liquidityUsed, liquidity / 2);

        // should not revert
        use(-200330, -200320, 2, bob);
    }

    function test_RevertWhen_utilizationLimitExceeded() public {
        hooks.setUtilizationLimit(0.5e36);
        uint128 liquidity = mint(-200330, -200320, 100e18, alice);
        use(-200330, -200320, liquidity / 2 + 1, bob);
        reserve(-200330, -200320, liquidity / 3, alice);
        TokenIdInfo memory info = StrykeHandlerV2Library.tokenIds(
            strykeHandler,
            uniswapV3Pool,
            address(hooks),
            -200330,
            -200320
        );
        assertEq(info.liquidityUsed, liquidity / 2 + 1);
        assertEq(info.reservedLiquidity, liquidity / 3);
        assertEq(info.totalLiquidity + info.reservedLiquidity, liquidity);

        // half of the liquidity used + 1
        uint256 rateExceeded = Math.mulDiv(liquidity / 2 + 1, 1e36, liquidity);
        useExpectRevert(
            -200330,
            -200320,
            1,
            bob,
            abi.encodeWithSelector(
                UtilizationLimitHooks.UtilizationLimitHooks__UtilizationLimitExceeded.selector,
                0.5e36,
                rateExceeded
            )
        );
    }

    function test_RevertWhen_InvalidUtilizationLimit() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                UtilizationLimitHooks.UtilizationLimitHooks__InvalidUtilizationLimit.selector,
                1e36 + 1
            )
        );
        hooks.setUtilizationLimit(1e36 + 1);
    }

    function mint(
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity,
        address receiver
    ) internal returns (uint128 liquidityMinted) {
        (uint256 amount0, uint256 amount1) = uniswapV3Pool.getAmountsForLiquidity(tickLower, tickUpper, liquidity);
        liquidityMinted = uniswapV3Pool.getLiquidityForAmounts(tickLower, tickUpper, amount0, amount1);
        deal(token0, address(this), amount0);
        deal(token1, address(this), amount1);
        IERC20(token0).approve(address(strykeHandler), amount0);
        IERC20(token1).approve(address(strykeHandler), amount1);
        strykeHandler.mintPosition(
            receiver,
            MintPositionParams({
                pool: uniswapV3Pool,
                hook: address(hooks),
                tickLower: tickLower,
                tickUpper: tickUpper,
                liquidity: liquidity
            }),
            address(this)
        );
        deal(token0, address(this), 0);
        deal(token1, address(this), 0);
    }

    function use(int24 tickLower, int24 tickUpper, uint128 liquidity, address caller) internal {
        strykeHandler.updateWhitelistedApps(caller, true);
        strykeHandler.usePosition(
            UsePositionParams({
                pool: uniswapV3Pool,
                hook: address(hooks),
                tickLower: tickLower,
                tickUpper: tickUpper,
                liquidityToUse: liquidity
            }),
            caller
        );
    }

    function useExpectRevert(
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity,
        address caller,
        bytes memory revertData
    ) internal {
        strykeHandler.updateWhitelistedApps(caller, true);
        vm.expectRevert(revertData);
        strykeHandler.usePosition(
            UsePositionParams({
                pool: uniswapV3Pool,
                hook: address(hooks),
                tickLower: tickLower,
                tickUpper: tickUpper,
                liquidityToUse: liquidity
            }),
            caller
        );
    }

    function reserve(int24 tickLower, int24 tickUpper, uint128 liquidity, address caller) internal {
        strykeHandler.reserveLiquidity(
            ReserveLiquidityParams({
                pool: uniswapV3Pool,
                hook: address(hooks),
                tickLower: tickLower,
                tickUpper: tickUpper,
                liquidity: liquidity
            }),
            caller
        );
    }

    function deployV3Factory() internal returns (address factory) {
        bytes memory bytecode = vm.readFileBinary("test/bin/uniswapV3Factory.bin");
        assembly {
            factory := create(0, add(bytecode, 0x20), mload(bytecode))
        }
    }

    function deployV3Router(address factory, address weth) internal returns (address router) {
        bytes memory initCode = abi.encodePacked(
            vm.readFileBinary("test/bin/uniswapV3Router.bin"),
            abi.encode(factory, weth)
        );
        assembly {
            router := create(0, add(initCode, 0x20), mload(initCode))
        }
    }

    function deployHandler(
        address factory,
        bytes memory poolInitCode,
        address router
    ) internal returns (address handler) {
        bytes memory initCode = abi.encodePacked(
            vm.readFileBinary("test/bin/strykeUniswapV3HandlerV2.bin"),
            abi.encode(factory, keccak256(poolInitCode), router)
        );
        assembly {
            handler := create(0, add(initCode, 0x20), mload(initCode))
        }
    }

    function deployPositionManager() internal returns (address positionManager) {
        bytes memory bytecode = vm.readFileBinary("test/bin/strykePositionManager.bin");
        assembly {
            positionManager := create(0, add(bytecode, 0x20), mload(bytecode))
        }
    }
}
