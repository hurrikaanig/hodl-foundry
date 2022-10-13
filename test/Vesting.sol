// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../src/FHodl.sol";
import "../src/Vesting.sol";
import "../src/interfaces/IFHodl.sol";

contract VestingTest is Test {

    Vesting vesting;
    FHodl fhodl;
    address user = 0x3a30Afe62A8382B8a76Bf80B8D42E5518829B6E2;

    function setUp() public {
        fhodl = new FHodl(1000 ether);
        vesting = new Vesting(IERC20(address(fhodl)));
    }

    function testVest() public {
        fhodl.mint(user, 10);

        vm.startPrank(user);
        fhodl.approve(address(vesting), 10);
        uint256 currentTimestamp = block.timestamp;
        vesting.vest(10, 1);
        vm.stopPrank();
        Vesting.UserInfo memory userInfo = vesting.getStaker(user);

        assertEq(userInfo.stakedAmount, 60);
        assertEq(userInfo.lastStakeTimestamp, currentTimestamp);
        assertEq(userInfo.vestingDurationIndex, 1);
        assertEq(fhodl.balanceOf(user), 0);
    }

    function testCannotVestWithLowerIndex() public {
        fhodl.mint(user, 20);
        vm.startPrank(user);
        fhodl.approve(address(vesting), 20);
        vesting.vest(10, 1);
        vm.expectRevert("Can't stake with lower vesting time");
        vesting.vest(10, 0);
        vm.stopPrank();
    }

    function testVestWithHigherIndex() public {
        fhodl.mint(user, 20);
        fhodl.transferOwnership(address(vesting));
        vm.startPrank(user);
        fhodl.approve(address(vesting), 20);
        vesting.vest(10, 1);
        vesting.vest(10, 2);
    }
}
