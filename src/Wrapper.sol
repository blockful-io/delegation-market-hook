// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract Wrapper is ERC20 {
    ERC20 govToken;

    constructor(ERC20 _govToken)
        ERC20(string.concat("Wrapped", _govToken.name()), string.concat("W", _govToken.symbol()))
    {
        govToken = _govToken;
    }

    function wrap(uint256 amount) public  {
        govToken.transferFrom(msg.sender, address(this), amount);
        _mint(msg.sender, amount);
    }

    function unwrap(uint256 amount) public  {
        _burn(msg.sender, amount);
        govToken.transferFrom(address(this), msg.sender, amount);
    }
}
