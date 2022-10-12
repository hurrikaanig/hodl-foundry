// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/FHodl.sol";
import "../src/Vesting.sol";
import "../src/interfaces/IFHodl.sol";

contract VestingTest is Test {

    Vesting vesting;
    FHodl fhodl;
    address user = 0x3a30Afe62A8382B8a76Bf80B8D42E5518829B6E2;

    function setUp() public {
        fhodl = new FHodl(1000 ether);
        vesting = new Vesting(IFHodl(address(fhodl)));
    }

    function testVest() public {
        fhodl.mint(10, user);

        vm.startPrank(user);
        fhodl.approve(address(vesting), 10);
        uint256 currentTimestamp = block.timestamp;
        vesting.vest(10, 1);
        vm.stopPrank();
        Vesting.UserInfo memory userInfo = vesting.getStaker(user);
        assertEq(userInfo.stakedAmount, 10);
        assertEq(userInfo.lastStakeTimestamp, currentTimestamp);
        assertEq(userInfo.claimedRewards, 0);
        emit log_named_uint("unlockTimestamp", userInfo.unlockTimestamp);
        emit log_uint(currentTimestamp + vesting.vestingDurations(1));
        assertEq(userInfo.unlockTimestamp, currentTimestamp + vesting.vestingDurations(1));
    }
}
