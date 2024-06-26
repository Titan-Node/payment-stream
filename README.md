Contract Audit: [Offical Link](https://0xmacro.com/library/audits/titan-node-1) | [PDF Copy](https://github.com/Titan-Node/payment-stream/blob/main/Payment-Stream-0xMarco-Audit.pdf)
# ERC-20 Payment Stream Contract
### Goal
The motivation of this contract is for a DAO treasury to pay an individual or entity for a work on a time based agreement. 

This contract receives ERC-20 tokens from a payer (such as an on-chain treasury) and allows time released claiming of tokens by the payee. Funds will become available for claiming on a linear scale as it gets closer to the `endDate` of the contract.

Two guardians are assigned that have the ability to terminate the contract and return the funds back to the treasury. (2 signatures required)

*Example: A DAO wants to hire Alice for a yearlong contract to maintain code for the project. Bob and Trudy are assigned by the community to ensure commitments are being met by Alice. Alice can use the `claim()` function at any time to receive their current allotment of funds. If Bob and Trudy lose confidence in the arrangement, they can both call the `terminate()` function to return the remaining unclaimed funds to the treasury.*

![Payment-Stream-Flowshart](https://raw.githubusercontent.com/Titan-Node/payment-stream/main/Payment-Stream-Flowshart.jpg)

## Installation
### Prerequisites 
Requires foundry forge and bun to be installed locally.

```
bun install
```

## Usage

This is a list of the most frequently needed commands.

### Clean

Delete the build artifacts and cache directories:

```
forge clean
```

### Compile

Compile the contracts:

```
forge build
```

### Coverage

Get a test coverage report:

```
forge coverage
```

### Deploy Factory Contract

[Quick Deployment](https://book.getfoundry.sh/forge/deploying):

1. Deploy contract:
```
forge create --rpc-url <rpc> \
    --private-key <pk> \
    --etherscan-api-key <api_key> \
    --verify \
    src/PaymentStreamFactory.sol:PaymentStreamFactory
```
Legend:
```
<rpc> - Chain RPC endpoint
<pk> - Contract deployers private key
<api_key> - Etherscan api key
```

2. Create streams

Visit Etherscan contract address to deploy unlimited streams through the web portal.

### Deploy Single Payment Stream

[Quick Deployment](https://book.getfoundry.sh/forge/deploying):

1. Deploy contract:
```
forge create --rpc-url <rpc> \
    --constructor-args <payee> <duration_in_seconds> <erc20_token_address> <amount_of_erc20_token_to_fund> [<term_signer_1_addr>,<term_signer_2_addr>] <term_receiver> \
    --private-key <pk> \
    --etherscan-api-key <api_key> \
    --verify \
    src/PaymentStream.sol:PaymentStream
```
Legend:
```
<rpc> - Chain RPC endpoint
<payee> - Who can claim tokens in the contract
<duration_in_seconds> - Seconds from the time the contract is deployed that all funds will be claimable
<erc20_token_address> - Address of the token being funded
<amount_of_erc20_token_to_fund> - Total amount of tokens claimable to the payee, smallest unit of account as per the token contract (ie 18 decimals)
<term_signer_1_addr> - Address of terminate signer
<term_signer_2_addr> - Address of terminate signer
<term_receiver> - Address of where funds will be sent if terminated (will send all funds in contract, including all over payments)
<pk> - Contract deployers private key
<api_key> - Etherscan api key
```

2. Fund the contract

Send the ERC-20 tokens that match `<erc20_token_address>` to the contract.

### Format

Format the contracts:

```
forge fmt
```

### Gas Usage

Get a gas report:

```
forge test --gas-report
```

### Lint

Lint the contracts:

```
bun run lint
```

### Test

Run the tests:

```
forge test
```

Generate test coverage and output result to the terminal:

```
bun run test:coverage
```

Generate test coverage with lcov report (you'll have to open the `./coverage/index.html` file in your browser, to do so
simply copy paste the path):

```
bun run test:coverage:report
```

## License

This project is licensed under MIT.
