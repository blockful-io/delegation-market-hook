// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;


import {Wrapper} from "./Wrapper.sol";


import {BalanceDelta, BalanceDeltaLibrary} from "@pancakeswap/v4-core/src/types/BalanceDelta.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "@pancakeswap/v4-core/src/types/BeforeSwapDelta.sol";
import {PoolId, PoolIdLibrary} from "@pancakeswap/v4-core/src/types/PoolId.sol";
import {IBinPoolManager} from "@pancakeswap/v4-core/src/pool-bin/interfaces/IBinPoolManager.sol";
import {BinBaseHook} from "./BinBaseHook.sol";

contract DelegationMarketHook is BinBaseHook, Wrapper {


    // NOTE: ---------------------------------------------------------
    // state variables should typically be unique to a pool
    // a single hook contract should be able to service multiple pools
    // ---------------------------------------------------------------
    uint256 oldBalance;
    uint256 newBalance;

    address currentBriber;
    uint256 feesAccrued;

    constructor(IPoolManager _poolManager, address _govToken) BaseHook(_poolManager) Wrapper(_govToken) {}

    function getHooksRegistrationBitmap() external pure override returns (uint16) {
        return _hooksRegistrationBitmapFrom(
            Permissions({
                beforeInitialize: false,
                afterInitialize: false,
                beforeMint: false,
                afterMint: false,
                beforeBurn: true,
                afterBurn: true,
                beforeSwap: false,
                afterSwap: false,
                beforeDonate: false,
                afterDonate: false,
                beforeSwapReturnsDelta: false,
                afterSwapReturnsDelta: false,
                afterMintReturnsDelta: false,
                afterBurnReturnsDelta: false
            })
        );
    }
    }

    // -----------------------------------------------
    // NOTE: see IHooks.sol for function documentation
    // -----------------------------------------------

    function beforeBurn(address, PoolKey calldata, IBinPoolManager.BurnParams calldata, bytes calldata)
     external override returns (bytes4) {
        oldBalance = balanceOf(address(poolManager));

        return BaseHook.beforeRemoveLiquidity.selector;
    }

    function afterBurn(address, PoolKey calldata, IBinPoolManager.BurnParams calldata, BalanceDelta, bytes calldata)
     external override returns (bytes4, BalanceDelta) {
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

