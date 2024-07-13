// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract Wrapper is ERC20 {
    ERC20 govToken;

    constructor(address _govToken)
        ERC20(string.concat("Wrapped", ERC20(_govToken).name()), string.concat("W", ERC20(_govToken).symbol()))
    {
        govToken = ERC20(_govToken);
    }

    function wrap(uint256 amount) public {
        govToken.transferFrom(msg.sender, address(this), amount);
        _mint(msg.sender, amount);
    }

    function unwrap(uint256 amount) public {
        _burn(msg.sender, amount);
        govToken.transferFrom(address(this), msg.sender, amount);
    }
}
