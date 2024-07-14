// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {GovToken} from "src/GovToken.sol";

import {IHooks} from "v4-core/src/interfaces/IHooks.sol";
import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {TickMath} from "v4-core/src/libraries/TickMath.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {BalanceDelta} from "v4-core/src/types/BalanceDelta.sol";
import {PoolId, PoolIdLibrary} from "v4-core/src/types/PoolId.sol";
import {CurrencyLibrary, Currency} from "v4-core/src/types/Currency.sol";
import {PoolSwapTest} from "v4-core/src/test/PoolSwapTest.sol";
import {Deployers} from "v4-core/test/utils/Deployers.sol";
import {DelegationMarketHook} from "../src/DelegationMarketHook.sol";
import {StateLibrary} from "v4-core/src/libraries/StateLibrary.sol";

contract DelegationMarketHookTest is Test, Deployers {
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;
    using StateLibrary for IPoolManager;

    DelegationMarketHook hook;
    PoolId poolId;
    GovToken govToken;
    address briber = address(0x2);


    function setUp() public {
        // creates the pool manager, utility routers, and test tokens
        Deployers.deployFreshManagerAndRouters();
        Deployers.deployMintAndApprove2Currencies();

        govToken = new GovToken();
        govToken.mint(address(this), 1_000_000 ether);
        govToken.mint(briber, 1_000_000 ether);
        govToken.approve(0x5991A2dF15A8F6A256D3Ec51E99254Cd3fb576A9, 10_000 ether);

        // Deploy the hook to an address with the correct flags
        address flags = address(uint160(Hooks.BEFORE_REMOVE_LIQUIDITY_FLAG | Hooks.AFTER_REMOVE_LIQUIDITY_FLAG));
        deployCodeTo("DelegationMarketHook.sol:DelegationMarketHook", abi.encode(manager, govToken), flags);
        hook = DelegationMarketHook(flags);

        // Create the pool
        key = PoolKey(currency0, Currency.wrap(address(govToken)), 3000, 60, IHooks(hook));
        poolId = key.toId();
        manager.initialize(key, SQRT_PRICE_1_1, ZERO_BYTES);

        // Provide full-range liquidity to the pool
        modifyLiquidityRouter.modifyLiquidity(
            key,
            IPoolManager.ModifyLiquidityParams(TickMath.minUsableTick(60), TickMath.maxUsableTick(60), 10_000 ether, 0),
            ZERO_BYTES
        );
    }

    function testCounterHooks() public {
        // positions were created in setup()


        // Perform a test swap //
        bool zeroForOne = true;
        int256 amountSpecified = -1e18; // negative number indicates exact input swap!
        BalanceDelta swapDelta = swap(key, zeroForOne, amountSpecified, ZERO_BYTES);
        // ------------------- //

        assertEq(int256(swapDelta.amount0()), amountSpecified);
    }

    function testLiquidityHooks() public {


        // remove liquidity
        int256 liquidityDelta = -1e18;
        modifyLiquidityRouter.modifyLiquidity(
            key,
            IPoolManager.ModifyLiquidityParams(
                TickMath.minUsableTick(60), TickMath.maxUsableTick(60), liquidityDelta, 0
            ),
            ZERO_BYTES
        );


    }

    function testSellDelegation() public {
        // positions were created in setup()
        assertEq(govToken.getVotes(briber), 0);

        vm.startPrank(briber);
        govToken.approve(address(hook), 1 ether);
        hook.sellDelegation();

        assertEq(govToken.getVotes(briber), 100_000);

    }
}
