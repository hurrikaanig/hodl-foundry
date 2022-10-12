// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IFHodl {

    function mint(uint256 _amount, address _to) external;

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}