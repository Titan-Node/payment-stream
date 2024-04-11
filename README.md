## Installation
### Prerequisites 
Requires foundry forge and bun to be installed locally.

```sh
bun install
```

## Usage

This is a list of the most frequently needed commands.

### Build

Build the contracts:

```sh
$ forge build
```

### Clean

Delete the build artifacts and cache directories:

```sh
$ forge clean
```

### Compile

Compile the contracts:

```sh
$ forge build
```

### Coverage

Get a test coverage report:

```sh
$ forge coverage
```

### Deploy

[Quick Deployment](https://book.getfoundry.sh/forge/deploying):

1. Deploy contract:
```sh
forge create --rpc-url <rpc> \
    --constructor-args <payee> <duration_in_seconds> <erc20_token_address> <amount_of_erc20_token_to_fund> [<term_signer_1_addr>,<term_signer_2_addr>] <term_receiver> \
    --private-key <pk> \
    --etherscan-api-key <api_key> \
    --verify \
    src/PaymentStream.sol:PaymentStream
```
2. Fund the contract
Send the ERC-20 tokens to the contract.

### Format

Format the contracts:

```sh
$ forge fmt
```

### Gas Usage

Get a gas report:

```sh
$ forge test --gas-report
```

### Lint

Lint the contracts:

```sh
$ bun run lint
```

### Test

Run the tests:

```sh
$ forge test
```

Generate test coverage and output result to the terminal:

```sh
$ bun run test:coverage
```

Generate test coverage with lcov report (you'll have to open the `./coverage/index.html` file in your browser, to do so
simply copy paste the path):

```sh
$ bun run test:coverage:report
```

## License

This project is licensed under MIT.
