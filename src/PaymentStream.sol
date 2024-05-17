// SPDX-License-Identifier: MIT
pragma solidity >=0.8.25;

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract PaymentStream {
    event Claimed(uint256 claimedAmount, uint256 remainingAmount);
    event TerminationInitiated(address initiator);
    event Terminated(uint256 remainingAmount);

    using SafeERC20 for IERC20;

    // Init
    address public immutable payee;
    uint256 public immutable duration;

    // Payment
    address public immutable paymentToken;
    uint256 public immutable paymentAmount;

    uint256 public immutable startTime;
    uint256 public immutable endTime;
    uint256 public claimedAmount;

    // Termination
    address public immutable termReceiver;

    struct TermSigner {
        bool isSigner;
        bool hasConfirmed; // Ensure fair confirmations
    }

    mapping(address => TermSigner) public termSigners;
    bool public isTerminated;
    uint256 public termConfirmations; // 2 required

    constructor(
        address _payee,
        uint256 _duration,
        address _paymentToken,
        uint256 _paymentAmount,
        address _termSigner1,
        address _termSigner2,
        address _termReceiver
    ) {
        require(
            _payee != address(0) && _termSigner1 != address(0) && _termSigner2 != address(0)
                && _termReceiver != address(0),
            "Invalid args"
        );
        require(_duration > 0 && _paymentToken != address(0) && _paymentAmount > 0, "Invalid args");

        payee = _payee;
        duration = _duration;

        paymentToken = _paymentToken;
        paymentAmount = _paymentAmount;

        // Set Term Signers
        termSigners[_termSigner1] = TermSigner(true, false);
        termSigners[_termSigner2] = TermSigner(true, false);
        termSigners[_payee] = TermSigner(true, false);

        termReceiver = _termReceiver;

        startTime = block.timestamp;
        endTime = startTime + duration;
    }

    function getClaimableAmount() public view returns (uint256 claimable) {
        uint256 currentTime = block.timestamp > endTime ? endTime : block.timestamp;
        uint256 timeElapsed = currentTime - startTime;

        claimable = (paymentAmount * timeElapsed / duration) - claimedAmount;
    }

    function claim() external {
        require(msg.sender == payee, "Not authorized");
        require(claimedAmount < paymentAmount, "All tokens have been claimed");
        require(!isTerminated, "Stream terminated");

        uint256 claimable = getClaimableAmount();

        claimedAmount += claimable;

        IERC20(paymentToken).safeTransfer(payee, claimable);

        emit Claimed(claimable, paymentAmount - claimedAmount);
    }

    function terminate() external {
        require(termSigners[msg.sender].isSigner, "Not authorized");
        require(!termSigners[msg.sender].hasConfirmed, "Already confirmed termination");
        require(claimedAmount < paymentAmount, "All tokens have been claimed");
        require(!isTerminated, "Stream terminated");

        if (termConfirmations == 1) {
            // Proceed with termination
            uint256 remainingTokens = IERC20(paymentToken).balanceOf(address(this));

            isTerminated = true;
            termSigners[msg.sender].hasConfirmed = true;
            termConfirmations++;

            IERC20(paymentToken).transfer(termReceiver, remainingTokens);

            emit Terminated(remainingTokens);
        } else {
            // First termination call
            termSigners[msg.sender].hasConfirmed = true;
            termConfirmations++;

            emit TerminationInitiated(msg.sender);
        }
    }
}
