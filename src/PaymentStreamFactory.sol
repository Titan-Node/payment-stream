// SPDX-License-Identifier: MIT
pragma solidity >=0.8.25;

import "./PaymentStream.sol";

contract PaymentStreamFactory {
    event StreamCreated(address paymentStream);

    function createStream(address payee, uint256 duration, address paymentToken, uint256 paymentAmount, address termSigner1, address termSigner2, address termReceiver) external returns (address ps) {
        ps = address(new PaymentStream(payee, duration, paymentToken, paymentAmount, termSigner1, termSigner2, termReceiver));

        emit StreamCreated(ps);
    }
}