// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../src/FHodl.sol";
import "../src/Vesting.sol";
import "../src/interfaces/IFHodl.sol";

contract VestingRewards is Test {

    Vesting vesting;
    FHodl fhodl;
    address user = 0x3a30Afe62A8382B8a76Bf80B8D42E5518829B6E2;
    address user2 = 0xe688b84b23f322a994A53dbF8E15FA82CDB71127;
    uint256 referralRatio = 2000;

    function setUp() public {
        fhodl = new FHodl(1000 ether);
        vesting = new Vesting(IERC20(address(fhodl)), 100, referralRatio);
    }

    function testOneReferralRewards() public {
        fhodl.mint(user, 10);
        fhodl.transferOwnership(address(vesting));

        vm.startPrank(user);
        fhodl.approve(address(vesting), 10);
        vesting.vest(10, 0, user2);
        vm.stopPrank();


        vm.warp(block.timestamp + 1 weeks);

        vm.startPrank(user);
        vesting.collectRewards();
        vm.stopPrank();
        
        assertTrue(fhodl.balanceOf(user) > 0);
        assertTrue(fhodl.balanceOf(user2) == fhodl.balanceOf(user) * referralRatio / 10000);
    }

    function testSetStakerRewards() public {
        fhodl.mint(user, 10);
        fhodl.transferOwnership(address(vesting));

        vm.startPrank(user);
        fhodl.approve(address(vesting), 10);
        vesting.vest(10, 0, user2);
        vm.stopPrank();


        vm.warp(block.timestamp + 1 weeks);

        vesting.setReferralRatio(0);
        vm.startPrank(user);
        vesting.collectRewards();
        vm.stopPrank();
        
        assertTrue(fhodl.balanceOf(user) > 0);
        assertTrue(fhodl.balanceOf(user2) == 0);
    }

}