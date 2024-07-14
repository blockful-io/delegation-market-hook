// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {GovToken} from "src/GovToken.sol";
import {Users} from "test/utils/Users.sol";
import {HookMiner} from "test/utils/HookMiner.sol";

import {IHooks} from "v4-core/src/interfaces/IHooks.sol";
import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {TickMath} from "v4-core/src/libraries/TickMath.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {BalanceDelta} from "v4-core/src/types/BalanceDelta.sol";
import {PoolId, PoolIdLibrary} from "v4-core/src/types/PoolId.sol";
import {CurrencyLibrary, Currency} from "v4-core/src/types/Currency.sol";
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
    GovToken weth;
    Users internal users;

    function setUp() public {
        // creates the pool manager, utility routers, and test tokens
        Deployers.deployFreshManagerAndRouters();

        govToken = new GovToken();
        weth = new GovToken();

        vm.label({account: address(govToken), newLabel: "GovToken"});
        vm.label({account: address(weth), newLabel: "WETH"});

        users.admin = createUser("Admin");
        users.briber = createUser("Briber");
        users.liquidityProvider = createUser("LiquityProvider");

        // hook contracts must have specific flags encoded in the address
        uint160 flags = (uint160(Hooks.BEFORE_REMOVE_LIQUIDITY_FLAG | Hooks.AFTER_REMOVE_LIQUIDITY_FLAG));

        // Mine a salt that will produce a hook address with the correct flags
        (address hookAddress, bytes32 salt) = HookMiner.find(
            users.admin, flags, type(DelegationMarketHook).creationCode, abi.encode(manager, address(govToken))
        );

        vm.prank(users.admin);
        hook = new DelegationMarketHook{salt: salt}(manager, address(govToken));
        assertEq(address(hook), hookAddress);

        // Create the pool
        key = PoolKey(Currency.wrap(address(weth)), Currency.wrap(address(hook)), 3000, 60, IHooks(hook));
        poolId = key.toId();
        manager.initialize(key, SQRT_PRICE_1_1, ZERO_BYTES);
    }

    function testCompleteCycle() public {
        // Provide full-range liquidity to the pool
        vm.startPrank(users.liquidityProvider);

        govToken.approve(address(hook), 10 ether);
        hook.wrap(10 ether);

        assertEq(hook.balanceOf(users.liquidityProvider), 10 ether);

        hook.approve(0x5991A2dF15A8F6A256D3Ec51E99254Cd3fb576A9, 10 ether);
        weth.approve(0x5991A2dF15A8F6A256D3Ec51E99254Cd3fb576A9, 10 ether);
        modifyLiquidityRouter.modifyLiquidity(
            key,
            IPoolManager.ModifyLiquidityParams(TickMath.minUsableTick(60), TickMath.maxUsableTick(60), 10 ether, 0),
            ZERO_BYTES
        );

        vm.stopPrank();

        // Perform a test swap //

        vm.startPrank(users.briber);

        weth.approve(0x2e234DAe75C793f67A35089C9d99245E1C58470b, 10 ether);
        bool zeroForOne = true;
        int256 amountSpecified = -1e18; // negative number indicates exact input swap!
        BalanceDelta swapDelta = swap(key, zeroForOne, amountSpecified, ZERO_BYTES);
        // ------------------- //

        assertEq(int256(swapDelta.amount0()), amountSpecified);

        vm.stopPrank();

        // Sell delegation
        assertEq(govToken.getVotes(users.briber), 0);

        vm.startPrank(users.briber);
        govToken.approve(address(hook), 1 ether);
        hook.sellDelegation();

        assertEq(govToken.getVotes(users.briber), 10 ether + 1 ether);

        vm.stopPrank();

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

    function createUser(string memory name) internal returns (address payable) {
        address payable user = payable(makeAddr(name));
        vm.deal({account: user, newBalance: 100 ether});
        deal({token: address(govToken), to: user, give: 1_000_000 ether});
        deal({token: address(weth), to: user, give: 1_000_000 ether});

        return user;
    }
}
