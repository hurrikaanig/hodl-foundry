// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../src/FHodl.sol";
import "../src/Vesting.sol";
import "../src/interfaces/IFHodl.sol";

contract VestingWithoutRewardsTest is Test {

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
        Vesting.UserInfo memory userInfo = vesting.getStaker(user);

        assertEq(userInfo.stakedAmount, 1000);
        assertEq(userInfo.vestingDurationIndex, 2);
        assertEq(fhodl.balanceOf(user), 0);
    }

    function testCannotUnvestBeforeUnlock() public {
        fhodl.mint(user, 10);
        fhodl.transferOwnership(address(vesting));
        vm.startPrank(user);
        fhodl.approve(address(vesting), 20);
        vesting.vest(10, 1);
        vm.expectRevert("Tokens not unlocked yet");
        vesting.unvest(10);
        vm.stopPrank();
    }

    function testUnvest() public {
        fhodl.mint(user, 10);
        fhodl.transferOwnership(address(vesting));
        vm.startPrank(user);
        fhodl.approve(address(vesting), 20);
        vesting.vest(10, 1);
        uint256 currentTimestamp = block.timestamp;
        Vesting.UserInfo memory userInfo = vesting.getStaker(user);
        vm.warp(userInfo.lastStakeTimestamp + vesting.vestingDurations(userInfo.vestingDurationIndex));
        assertEq(fhodl.balanceOf(user), 0);
        vesting.unvest(10);
        vm.stopPrank();
        assertEq(fhodl.balanceOf(user), 10);
    }

    function testCannotUnvestMoreThanStaked() public {
        fhodl.mint(user, 10);
        fhodl.transferOwnership(address(vesting));
        vm.startPrank(user);
        fhodl.approve(address(vesting), 20);
        vesting.vest(10, 1);
        uint256 currentTimestamp = block.timestamp;
        Vesting.UserInfo memory userInfo = vesting.getStaker(user);
        vm.warp(userInfo.lastStakeTimestamp + vesting.vestingDurations(userInfo.vestingDurationIndex));
        vm.expectRevert("Not enough staked");
        vesting.unvest(11);
        vm.stopPrank();
    }

    function testUnvestInTwoTimes() public {
        fhodl.mint(user, 10);
        fhodl.transferOwnership(address(vesting));
        vm.startPrank(user);
        fhodl.approve(address(vesting), 20);
        vesting.vest(10, 1);
        uint256 currentTimestamp = block.timestamp;
        Vesting.UserInfo memory userInfo = vesting.getStaker(user);
        vm.warp(userInfo.lastStakeTimestamp + vesting.vestingDurations(userInfo.vestingDurationIndex));
        vesting.unvest(4);
        assertEq(fhodl.balanceOf(user), 4);
        vesting.unvest(6);
        assertEq(fhodl.balanceOf(user), 10);
        vm.stopPrank();
    }
}
