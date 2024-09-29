// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
// you can use console with test (Test, console) as well, prints stuff out e.g test
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
import "forge-std/console.sol";

contract FundMeTest is Test {
    FundMe fundme;

    address USER = makeAddr("user");
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant SEND_VALUE = 1 ether;
    uint256 constant GAS_PRICE = 1 ether;

    // deploy in test folder use this
    function setUp() external {
        DeployFundMe deployfundme = new DeployFundMe();
        fundme = deployfundme.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testMinimumUSDisFive() public view {
        assertEq(fundme.MINIMUM_USD(), 1e18);
    }

    function testOwner() public view {
        assertEq(fundme.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public view {
        uint256 version = fundme.getVersion();
        assertEq(version, 6);
    }

    function testFundFailsWIthoutEnoughETH() public {
        vm.expectRevert(); // <- The next line after this one should revert! If not test fails.
        fundme.fund(); // <- We send 0 value
    }

    function testFundUpdatesFundDataStructure() public {
        vm.prank(USER);
        fundme.fund{value: SEND_VALUE}();
        uint256 amountFunded = fundme.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public {
        vm.prank(USER);
        fundme.fund{value: SEND_VALUE}();
        vm.stopPrank();

        address funder = fundme.getFunder(0);
        assertEq(funder, USER);
    }

    modifier funded() {
        vm.prank(USER);
        fundme.fund{value: SEND_VALUE}();
        assert(address(fundme).balance > 0);
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.prank(USER); // Set the USER as the msg.sender (not the owner)
        vm.expectRevert(); // Expect revert because USER is not the owner
        fundme.withdraw(); // Attempt to withdraw funds as USER (should fail)
    }

    function testWithdrawFromASingleFunder() public funded {
        //Arrange
        uint256 startingFundMeBalance = address(fundme).balance;
        uint256 startingOwnerBalance = fundme.getOwner().balance;

        //Act
        // uint256 gasStart = gasleft(); //1000
        vm.txGasPrice(GAS_PRICE); // 200
        vm.startPrank(fundme.getOwner());
        fundme.withdraw();
        vm.stopPrank();
        // uint256 gasEnd = gasleft(); //500
        // uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        // console.log(gasUsed);

        //Assert
        uint256 endingFundMeBalance = address(fundme).balance;
        uint256 endingOwnerBalance = fundme.getOwner().balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance
        );
    }

    function testWithdrawalFromMultipleFunders() public funded {
        // Arrange
        uint160 numberOfFunders = 10; // If you want to use numbers to generate addresses it has to be in unit160
        uint160 startingFunderIndex = 1;
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            //vm.prank new address
            //vm.deal new address
            //address
            hoax(address(i), SEND_VALUE);
            fundme.fund{value: SEND_VALUE}();
        }
        //Act
        uint256 startingOwnerBalance = fundme.getOwner().balance;
        uint256 startingFundMeBalance = address(fundme).balance;
        vm.startPrank(fundme.getOwner());
        fundme.withdraw();
        vm.stopPrank();

        //Assert
        assert(address(fundme).balance == 0);
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundme.getOwner().balance
        );
    }

    function testWithdrawalFromMultipleFunderscheaper() public funded {
        // Arrange
        uint160 numberOfFunders = 10; // If you want to use numbers to generate addresses it has to be in unit160
        uint160 startingFunderIndex = 1;
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            //vm.prank new address
            //vm.deal new address
            //address
            hoax(address(i), SEND_VALUE);
            fundme.fund{value: SEND_VALUE}();
        }
        //Act
        uint256 startingOwnerBalance = fundme.getOwner().balance;
        uint256 startingFundMeBalance = address(fundme).balance;
        vm.startPrank(fundme.getOwner());
        fundme.cheaperWithdraw();
        vm.stopPrank();

        //Assert
        assert(address(fundme).balance == 0);
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundme.getOwner().balance
        );
    }
}
