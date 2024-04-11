// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { console2 } from "forge-std/src/console2.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";

import { PaymentStream } from "../src/PaymentStream.sol";

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token_ERC20 is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) { }

    function mint(address to, uint256 value) public virtual {
        _mint(to, value);
    }

    function burn(address from, uint256 value) public virtual {
        _burn(from, value);
    }
}

contract PaymentStreamTest is PRBTest, StdCheats {
    PaymentStream internal ps;
    Token_ERC20 internal paymentToken;

    address internal payee;
    address[2] internal termSigners;

    /// @dev A function invoked before each test case is run.
    function setUp() public virtual {
        // Instantiate the contract-under-test.
        payee = vm.addr(0xA11CE);
        termSigners = [vm.addr(0xB0B), vm.addr(0xC0C)];

        paymentToken = new Token_ERC20("TEST", "TEST");
        paymentToken.mint(address(this), 7e18);

        uint256 duration = 1 weeks;

        ps = new PaymentStream(payee, duration, address(paymentToken), 7e18, termSigners, termSigners[0]);

        paymentToken.transfer(address(ps), 7e18);
    }

    function test_Claim() external {
        // Go to half-way point
        vm.warp(ps.startTime() + (1 weeks / 2));

        assertEq(ps.getClaimableAmount(), 3.5e18);

        vm.startPrank(payee);
        ps.claim();
        vm.stopPrank();

        // Payout successful and no further claim
        assertEq(ps.getClaimableAmount(), 0);
        assertEq(ps.claimedAmount(), 3.5e18);
        assertEq(paymentToken.balanceOf(payee), 3.5e18);

        // Make sure at the end the payout is the remaining half
        vm.warp(ps.startTime() + 1 weeks);

        assertEq(ps.getClaimableAmount(), 3.5e18);

        // Ensure the amount doesn't change
        vm.warp(ps.startTime() + 4 weeks);

        assertEq(ps.getClaimableAmount(), 3.5e18);
    }

    function test_Terminate() external {
        // First term confirmation
        vm.startPrank(termSigners[0]);
        ps.terminate();

        assertEq(ps._hasConfirmed(termSigners[0]), true);
        assertEq(ps.termConfirmations(), 1);
        vm.stopPrank();

        // Second term confirmation
        vm.startPrank(termSigners[1]);
        ps.terminate();
        vm.stopPrank();

        assertEq(ps.isTerminated(), true);
        assertEq(paymentToken.balanceOf(termSigners[0]), 7e18);
    }

    function testRevert_ClaimEdges1() external {
        // Test unauthorized
        vm.expectRevert("Not authorized");
        ps.claim();

        // Test terminated
        vm.startPrank(termSigners[0]);
        ps.terminate();
        vm.stopPrank();
        vm.startPrank(termSigners[1]);
        ps.terminate();
        vm.stopPrank();

        vm.expectRevert("Stream terminated");
        vm.startPrank(payee);
        ps.claim();
        vm.stopPrank();
    }

    function testRevert_ClaimEdges2() external {
        // Test all tokens claimed
        vm.warp(ps.startTime() + 1 weeks);
        vm.startPrank(payee);
        ps.claim();

        vm.expectRevert("All tokens have been claimed");
        ps.claim();
        vm.stopPrank();
    }

    function testRevert_TerminateEdges() external {
        // Not authorized
        vm.expectRevert("Not authorized");
        ps.terminate();
        // Already confirmed
        vm.startPrank(termSigners[0]);
        ps.terminate();

        vm.expectRevert("Already confirmed termination");
        ps.terminate();
        vm.stopPrank();
        // Tokens claimed
        vm.warp(ps.startTime() + 1 weeks);
        vm.startPrank(payee);
        ps.claim();
        vm.stopPrank();

        vm.startPrank(termSigners[1]);
        vm.expectRevert("All tokens have been claimed");
        ps.terminate();
        vm.stopPrank();
    }

    function test_TerminateAmountEdge() external {
        vm.warp(ps.startTime() + 4 days + 5 hours + 5 minutes);
        vm.startPrank(payee);
        uint256 claimable = ps.getClaimableAmount();
        ps.claim();
        vm.stopPrank();

        vm.startPrank(termSigners[1]);
        ps.terminate();
        vm.stopPrank();
        vm.startPrank(termSigners[0]);
        ps.terminate();
        vm.stopPrank();

        assertEq(paymentToken.balanceOf(termSigners[0]), ps.paymentAmount() - claimable);
        assertEq(paymentToken.balanceOf(address(ps)), 0);
    }
}
