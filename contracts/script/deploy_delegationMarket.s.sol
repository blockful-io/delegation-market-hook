// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import {DelegationMarket} from "../src/DelegationMarket.sol";

contract CounterScript is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        new DelegationMarket(address(0x912CE59144191C1204E64559FE8253a0e49E6548));
    }
}


// forge script script/deploy_delegationMarket.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast
