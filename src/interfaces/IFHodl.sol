// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IFHodl {

    function mint(address _to, uint256 _amount) external;

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function balanceOf(address account) external returns (uint256);
}