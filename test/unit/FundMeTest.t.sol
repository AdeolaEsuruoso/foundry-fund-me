//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    address USER = makeAddr("user");
    address USER_1 = makeAddr("User_1");
    address USER_2 = makeAddr("USER_2");
    uint256 constant SEND_VALUE = 1e17;
    uint256 constant SEND_VALUE_1 = 2e17;
    uint256 constant SEND_VALUE_2 = 3e17;

    uint256 constant STARTING_BALANCE = 20e18;
    uint256 GAS_PRICE = 1;

    function setUp() external {
        //fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(address(USER), STARTING_BALANCE);
        vm.deal(address(USER_1), STARTING_BALANCE);
        vm.deal(address(USER_2), STARTING_BALANCE);
    }

    function testMinimumDollarIsFive() public view {
        console.log(fundMe.MINIMUM_USD());
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public view {
        console.log(fundMe.getOwner());
        console.log(msg.sender);
        console.log(address(this));
        assertEq(fundMe.getOwner(), msg.sender);
    }

    // What can we do to work with addresses outside our system?
    // 1. Unit
    //    - Testing a specific part of our code
    // 2. Integration
    //    - Testing how our code works with other parts of our code
    // 3. Forked
    //    - Testing our code on a simulated real environment
    // 4. Staging
    //    - Testing our code in a real environment that is not prod

    function testPriceFeedVersionIsAccurate() public view {
        uint256 version = fundMe.getVersion();
        console.log(version);
        assertGe(version, 4);
    }

    function testFundFailsWithoutEnoughETH() public {
        vm.expectRevert(); // hey, the next line should revert
        // assert(This tx fails/reverts)
        fundMe.fund{value: 0}();
    }

    function testFundUpdateFundedDataStructure() public funded {
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    // Parent node
    modifier funded() {
        // This is a modifier that will be used in my test to help
        // avoid repeating the next two line of code where necessary
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    // Child Node
    function testAddsFunderToArrayOfFunders() public funded {
        address funder = fundMe.getFunder(0); // checks who is really at the first index of funders array
        assertEq(funder, USER); // Confirms the check
    }

    function testAddsMultipleFundersToArrayOfFunders() public funded {
        address funder;
        // vm.prank(USER); //This makes USER be the on to send the next transaction
        // fundMe.fund{value: SEND_VALUE}(); // USER sends this transaction
        funder = fundMe.getFunder(0);
        assertEq(funder, USER);

        vm.prank(USER_1); //This makes USER be the on to send the next transaction
        fundMe.fund{value: SEND_VALUE_1}(); // USER sends this transaction
        funder = fundMe.getFunder(1);
        assertEq(funder, USER_1);

        vm.prank(USER_2); //This makes USER be the on to send the next transaction
        fundMe.fund{value: SEND_VALUE_2}(); // USER sends this transaction
        funder = fundMe.getFunder(2);
        assertEq(funder, USER_2);
    }

    /**
     * // Instead of repeating myself 3 times, use ARRAYS and a LOOP:
     * function testAddsMultipleFundersToArrayOfFunders() public {
     *     // No repeated code
     *     address[3] memory users = [USER, USER_1, USER_2];
     *     uint256[3] memory values = [SEND_VALUE, SEND_VALUE_1, SEND_VALUE_2];
     *
     *     for (uint256 i = 0; i < users.length; i++) {
     *         vm.prank(users[i]);
     *         fundMe.fund{value: values[i]}();
     *         assertEq(fundMe.getFunder(i), users[i]); // One assertEq covers all cases
     *     }
     * }
     */

    /**
     *  // Using Foundry's makeAddr in a loop
     *  function testAddsMultipleFundersToArrayOfFunders() public {
     *      uint256 numFunders = 5;
     *
     *      for (uint256 i = 0; i < numFunders; i++) {
     *          address funder = makeAddr(string(abi.encodePacked("funder", i)));
     *          vm.deal(funder, STARTING_BALANCE);
     *          vm.prank(funder);
     *          fundMe.fund{value: SEND_VALUE}();
     *          assertEq(fundMe.getFunder(i), funder);
     *      }
     * }
     */

    function testOnlyOwnerCanWithdraw() public funded {
        // vm.prank(USER);
        // fundMe.fund{value: SEND_VALUE}();

        // All other code logic goes here...
        vm.prank(USER); // The owner is actually msg.sender so this will revert
        vm.expectRevert();
        fundMe.withdraw();
    }

    function testWithdrawWithASingleFunder() public funded {
        // Modifier comes first to fund
        // Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        // Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(endingOwnerBalance, startingOwnerBalance + startingFundMeBalance);
    }

    function testWithdrawFromMultipleFunders() public funded {
        // Arrange funders
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1; //sometimes, zero address has issues so this is better
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            // vm.prank new address
            // vm.deal new address
            hoax(address(i), SEND_VALUE); // hoax = vm.deal + vm.prank  i.e gives an prefunded address
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalace = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        uint256 gasStart = gasleft();
        vm.txGasPrice(GAS_PRICE);
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        uint256 gasEnd = gasleft();
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        console.log("Gas used cost", gasUsed);

        // Assertion
        assertEq(address(fundMe).balance, 0);
        assertEq(startingOwnerBalace + startingFundMeBalance, fundMe.getOwner().balance);
    }

    function testWithdrawFromMultipleFundersCheaper() public funded {
        // Arrange funders
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1; //sometimes, zero address has issues so this is better
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            // vm.prank new address
            // vm.default new address
            hoax(address(i), SEND_VALUE); // hoax = vm.deal + vm.prank  i.e gives an prefunded address
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalace = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        uint256 gasStart = gasleft();
        vm.txGasPrice(GAS_PRICE);
        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        uint256 gasEnd = gasleft();
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        console.log("Gas used cost", gasUsed);

        // Assertion
        assertEq(address(fundMe).balance, 0);
        assertEq(startingOwnerBalace + startingFundMeBalance, fundMe.getOwner().balance);
    }
}
