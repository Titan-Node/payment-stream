// SPDX-License-Identifier: MIT
pragma solidity >=0.8.25;

import "./PaymentStream.sol";

contract PaymentStreamFactory {
    event StreamCreated(address paymentStream);

    function createStream(address payee, uint256 duration, address paymentToken, uint256 paymentAmount, address[2] memory termSigners, address termReceiver) external returns (address ps) {
        ps = address(new PaymentStream(payee, duration, paymentToken, paymentAmount, termSigners, termReceiver));

        emit StreamCreated(ps);
    }
}