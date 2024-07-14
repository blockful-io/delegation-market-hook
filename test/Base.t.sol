// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import {Test} from "forge-std/Test.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Users} from "test/utils/Users.sol";

import {GovToken} from "src/GovToken.sol";
import {DelegationMarketHook} from "src/DelegationMarketHook.sol";

/// @notice Base test contract with common logic needed by all tests.
abstract contract BaseTest is Test {
    /*//////////////////////////////////////////////////////////////////////////
                                     VARIABLES
    //////////////////////////////////////////////////////////////////////////*/
    GovToken govToken;
    DelegationMarketHook hook;

    Users internal users;

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual {
        // Deploy the base test contracts.
        govToken = new GovToken();
        // hook = new DelegationMarketHook();

        // Label the base test contracts.
        vm.label({account: address(govToken), newLabel: "GovToken"});

        users.briber = createUser("Briber");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Generates a user, labels its address, funds it with test assets, and approves the protocol contracts.
    function createUser(string memory name) internal returns (address payable) {
        address payable user = payable(makeAddr(name));
        vm.deal({account: user, newBalance: 100 ether});
        deal({token: address(govToken), to: user, give: 1_000_000e18});

        return user;
    }
}
