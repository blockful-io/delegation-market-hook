// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {BaseHook} from "v4-periphery/BaseHook.sol";
import {Wrapper} from "./Wrapper.sol";


contract DelegationMarket is Wrapper  {

    constructor(address _govToken) Wrapper(_govToken) {}

    function sellDelegation() public {
        govToken.transferFrom(msg.sender, address(this), 1e17);

        govToken.delegate(msg.sender);
    }
}
