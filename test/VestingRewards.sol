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
    uint256 rewardPerSec = 100;

    function setUp() public {
        fhodl = new FHodl(1000 ether);
        vesting = new Vesting(IERC20(address(fhodl)), rewardPerSec, 0);
    }
    
    function testOneStakerRewards() public {
        fhodl.mint(user, 10);
        fhodl.transferOwnership(address(vesting));

        vm.startPrank(user);
        fhodl.approve(address(vesting), 10);
        vesting.vest(10, 0, address(0));
        vm.stopPrank();


        vm.warp(block.timestamp + 1 weeks);

        vm.startPrank(user);
        vesting.collectRewards();
        vm.stopPrank();
        
        emit log_uint(fhodl.balanceOf(user));
        assertTrue(fhodl.balanceOf(user) > 0);
    }

    function testOneSecondRewards(uint256 _amountStaked) public {
        vm.assume(_amountStaked < 1000000000e18);
        fhodl.mint(user, 100);
        fhodl.transferOwnership(address(vesting));

        vm.startPrank(user);
        fhodl.approve(address(vesting), 100);
        vesting.vest(100, 0, address(0));
        vm.stopPrank();


        vm.warp(block.timestamp + 1);

        vm.startPrank(user);
        vesting.collectRewards();
        vm.stopPrank();
        
        assertTrue(fhodl.balanceOf(user) == 100);
    }

    function testOneStakerRewards(uint256 _stakedAmount, uint256 _vestingIndex, uint256 _timeToWait) public {
        vm.assume(_vestingIndex < 4);
        vm.assume(_timeToWait < 1000000000);
        vm.assume(_stakedAmount < 1000000000e18);
        fhodl.mint(user, _stakedAmount);
        fhodl.transferOwnership(address(vesting));

        vm.startPrank(user);
        fhodl.approve(address(vesting), _stakedAmount);
        vesting.vest(_stakedAmount, _vestingIndex, address(0));
        vm.stopPrank();


        vm.warp(block.timestamp + _timeToWait);

        vm.startPrank(user);
        vesting.collectRewards();
        vm.stopPrank();
    }

    function testVestingTwoTimes() public {
        fhodl.mint(user, 10);
        fhodl.transferOwnership(address(vesting));

        vm.startPrank(user);
        fhodl.approve(address(vesting), 10);
        vesting.vest(5, 0, address(0));
        vm.stopPrank();

        vm.warp(block.timestamp + 1 weeks);

        vm.startPrank(user);
        vesting.vest(5, 0, address(0));
        vm.stopPrank();

        assertTrue(fhodl.balanceOf(user) > 0);
    }

    function testTwoStakersDifferentAmount() public {
        fhodl.mint(user, 10);
        fhodl.mint(user2, 10);
        fhodl.transferOwnership(address(vesting));

        vm.startPrank(user);
        fhodl.approve(address(vesting), 10);
        vesting.vest(10, 0, address(0));
        vm.stopPrank();
        vm.startPrank(user2);
        fhodl.approve(address(vesting), 10);
        vesting.vest(5, 0, address(0));
        vm.stopPrank();

        vm.warp(block.timestamp + 1 weeks);

        vm.startPrank(user);
        vesting.collectRewards();
        vm.stopPrank();
        vm.startPrank(user2);
        vesting.collectRewards();
        vm.stopPrank();

        assertApproxEqAbs(fhodl.balanceOf(user), fhodl.balanceOf(user2) * 2, 10);
    }

    function testTwoStakersDifferentVesting() public {
        fhodl.mint(user, 10);
        fhodl.mint(user2, 10);
        fhodl.transferOwnership(address(vesting));

        vm.startPrank(user);
        fhodl.approve(address(vesting), 10);
        vesting.vest(10, 0, address(0));
        vm.stopPrank();
        vm.startPrank(user2);
        fhodl.approve(address(vesting), 10);
        vesting.vest(10, 2, address(0));
        vm.stopPrank();

        vm.warp(block.timestamp + 1 weeks);

        vm.startPrank(user);
        vesting.collectRewards();
        vm.stopPrank();
        vm.startPrank(user2);
        vesting.collectRewards();
        vm.stopPrank();

        assertApproxEqAbs(fhodl.balanceOf(user) * 50, fhodl.balanceOf(user2), 10);
    }

    function testTwoStakers() public {
        fhodl.mint(user, 10);
        fhodl.mint(user2, 10);
        fhodl.transferOwnership(address(vesting));

        vm.startPrank(user);
        fhodl.approve(address(vesting), 10);
        vesting.vest(10, 0, address(0));
        vm.stopPrank();
        vm.startPrank(user2);
        fhodl.approve(address(vesting), 10);
        vesting.vest(10, 0, address(0));
        vm.stopPrank();

        vm.warp(block.timestamp + 1 weeks);

        vm.startPrank(user);
        vesting.collectRewards();
        vm.stopPrank();
        vm.startPrank(user2);
        vesting.collectRewards();
        vm.stopPrank();

        assertEq(fhodl.balanceOf(user), fhodl.balanceOf(user2));
    }
}