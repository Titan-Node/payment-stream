// SPDX-License-Identifier: MIT
pragma solidity >=0.8.25;

import { UD60x18, ud } from "@prb/math/src/UD60x18.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";

contract PaymentStream {
    // Init
    address public payee;
    uint256 public duration;

    // Payment
    address public paymentToken;
    uint256 public paymentAmount;

    uint256 public startTime;
    uint256 public endTime;
    uint256 public claimedAmount;

    // Termination
    mapping(address => bool) public isTermSigner;
    address public termReceiver;
    bool public isTerminated;

    uint256 public termConfirmations; // 2 required
    mapping(address => bool) public _hasConfirmed; // Ensure fair confirmations

    constructor(
        address _payee,
        uint256 _duration,
        address _paymentToken,
        uint256 _paymentAmount,
        address[2] memory _termSigners,
        address _termReceiver
    ) {
        require(_duration > 0 && _paymentToken != address(0) && _paymentAmount > 0, "Invalid args");

        payee = _payee;
        duration = _duration;

        paymentToken = _paymentToken;
        paymentAmount = _paymentAmount;

        // Set Term Signers
        isTermSigner[_termSigners[0]] = true;
        isTermSigner[_termSigners[1]] = true;
        isTermSigner[_payee] = true;

        termReceiver = _termReceiver;

        startTime = block.timestamp;
        endTime = startTime + duration;
    }

    function getClaimableAmount() public view returns (uint256 claimable) {
        uint256 currentTime = block.timestamp > endTime ? endTime : block.timestamp;
        uint256 timeElapsed = currentTime - startTime;

        claimable = (ud(paymentAmount).mul(ud(timeElapsed).div(ud(duration)))).intoUint256() - claimedAmount;
    }

    function claim() external {
        require(msg.sender == payee, "Not authorized");
        require(claimedAmount < paymentAmount, "All tokens have been claimed");
        require(!isTerminated, "Stream terminated");

        uint256 claimable = getClaimableAmount();

        claimedAmount += claimable;

        IERC20(paymentToken).transfer(payee, claimable);
    }

    function terminate() external {
        require(isTermSigner[msg.sender], "Not authorized");
        require(!_hasConfirmed[msg.sender], "Already confirmed termination");
        require(claimedAmount < paymentAmount, "All tokens have been claimed");
        require(!isTerminated, "Stream terminated");

        if (termConfirmations == 1) {
            // Proceed with termination
            uint256 remainingTokens = IERC20(paymentToken).balanceOf(address(this));
            
            isTerminated = true;
            _hasConfirmed[msg.sender] = true;
            termConfirmations++;

            IERC20(paymentToken).transfer(termReceiver, remainingTokens);
        } else {
            // First termination call
            _hasConfirmed[msg.sender] = true;
            termConfirmations++;
        }
    }
}
