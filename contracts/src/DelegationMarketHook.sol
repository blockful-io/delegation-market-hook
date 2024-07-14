// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {BaseHook} from "v4-periphery/BaseHook.sol";
import {Wrapper} from "./Wrapper.sol";

import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "v4-core/src/types/PoolId.sol";
import {BalanceDelta} from "v4-core/src/types/BalanceDelta.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "v4-core/src/types/BeforeSwapDelta.sol";

contract DelegationMarketHook is BaseHook, Wrapper {
    using PoolIdLibrary for PoolKey;

    // NOTE: ---------------------------------------------------------
    // state variables should typically be unique to a pool
    // a single hook contract should be able to service multiple pools
    // ---------------------------------------------------------------
    uint256 oldBalance;
    uint256 newBalance;

    address currentBriber;
    uint256 feesAccrued;

    constructor(IPoolManager _poolManager, address _govToken) BaseHook(_poolManager) Wrapper(_govToken) {}

    function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
        return Hooks.Permissions({
            beforeInitialize: false,
            afterInitialize: false,
            beforeAddLiquidity: false,
            afterAddLiquidity: false,
            beforeRemoveLiquidity: true,
            afterRemoveLiquidity: true,
            beforeSwap: false,
            afterSwap: false,
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: false,
            afterSwapReturnDelta: false,
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        });
    }

    // -----------------------------------------------
    // NOTE: see IHooks.sol for function documentation
    // -----------------------------------------------

    function beforeRemoveLiquidity(
        address sender,
        PoolKey calldata key,
        IPoolManager.ModifyLiquidityParams calldata,
        bytes calldata
    ) external override returns (bytes4) {
        oldBalance = balanceOf(address(poolManager));

        return BaseHook.beforeRemoveLiquidity.selector;
    }

    function afterRemoveLiquidity(
        address sender,
        PoolKey calldata key,
        IPoolManager.ModifyLiquidityParams calldata params,
        BalanceDelta delta,
        bytes calldata hookData
    ) external override returns (bytes4, BalanceDelta) {
        newBalance = balanceOf(address(poolManager));
        uint256 feesToPay;

        if (newBalance == 0) {
            feesToPay = feesAccrued;
        } else {
            feesToPay = feesAccrued * (oldBalance - newBalance) / oldBalance;
        }

        govToken.transferFrom(address(this), sender, balanceOf(sender) + feesToPay);
        _burn(sender, balanceOf(sender));

        return (BaseHook.afterRemoveLiquidity.selector, delta);
    }

    function sellDelegation() public {
        govToken.transferFrom(msg.sender, address(this), 1 ether);

        govToken.delegate(msg.sender);

        feesAccrued += 1 ether;
    }
}

forge verify-contract --contract-path src/DelegationMarket.sol:DelegationMarket --rpc-url $RPC_URL --etherscan-api-key $ETHERSCAN_API_KEY --constructor-args 0x912CE59144191C1204E64559FE8253a0e49E6548