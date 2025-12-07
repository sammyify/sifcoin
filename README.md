# sifcoin

A SIP-010 compatible fungible token implemented in [Clarity](https://docs.stacks.co/write-smart-contracts/clarity) and managed with [Clarinet](https://docs.hiro.so/clarinet/introduction).

This repository defines the **Sifcoin (SIF)** token as a smart contract that can be deployed to the Stacks blockchain.

## Project structure

- `Clarinet.toml` – Clarinet project configuration
- `contracts/sifcoin.clar` – Sifcoin fungible token contract
- `tests/sifcoin.test.ts` – Example Vitest test file (you can extend this with real tests)
- `settings/*.toml` – Network configuration for Mainnet, Testnet, and Devnet

## Prerequisites

- **Clarinet** CLI (already installed):
  ```bash path=null start=null
  clarinet --version
  ```
- Node.js and npm (for running tests) – optional but recommended

## Sifcoin token overview

- **Name:** Sifcoin
- **Symbol:** SIF
- **Decimals:** `6` (i.e. 1 SIF = 1_000_000 base units)
- **Standard:** [SIP-010 fungible token](https://github.com/stacksgov/sips/blob/main/sips/sip-010/sip-010-ft-standard.md)

### Core capabilities

The `contracts/sifcoin.clar` contract exposes the typical SIP-010 interface:

- `transfer(recipient, amount, memo)` – transfer tokens from the caller to `recipient`
- `transfer-from(sender, recipient, amount, memo)` – transfer tokens on behalf of `sender` using an existing allowance
- `approve(spender, amount)` – set/update the allowance for `spender`
- `mint(recipient, amount)` – mint new tokens to `recipient` (restricted to the contract owner)
- Read-only views:
  - `get-name()` – returns `(optional (string-ascii ...))`
  - `get-symbol()` – returns `(optional (string-ascii ...))`
  - `get-decimals()` – returns `uint`
  - `get-total-supply()` – returns current total supply
  - `get-balance-of(owner)` – returns the balance of `owner`
  - `get-allowance(owner, spender)` – returns allowance for `spender` from `owner`

> Note: In this simple implementation, the **contract owner** is defined as the principal that deploys the contract. Only the owner can call `mint`.

## Getting started

From the project root (`sifcoin`):

1. **Check contract syntax**

   ```bash path=null start=null
   clarinet check
   ```

   This parses and type-checks all Clarity contracts in the `contracts/` directory.

2. **Open a Clarinet console (optional)**

   ```bash path=null start=null
   clarinet console
   ```

   Inside the console you can call functions on the `sifcoin` contract, for example:

   ```clarity path=null start=null
   (contract-call? .sifcoin get-total-supply)
   ```

3. **Run tests (optional)**

   Install dependencies and run the Vitest test suite:

   ```bash path=null start=null
   npm install
   npm test
   ```

   Extend `tests/sifcoin.test.ts` with calls to your contract using the Clarinet JS SDK.

## Interacting with the contract (simnet example)

Inside `clarinet console` you can simulate typical flows.

### Minting tokens (owner only)

```clarity path=null start=null
;; Assuming the console default deployer is the contract owner
(contract-call? .sifcoin mint tx-sender u1000000) ;; mint 1.0 SIF (with 6 decimals)
```

### Checking balances

```clarity path=null start=null
(define-constant alice tx-sender)
(contract-call? .sifcoin get-balance-of alice)
```

### Transferring tokens

```clarity path=null start=null
(define-constant alice tx-sender)
(define-constant bob 'ST2J...YOUR-BOB-ADDRESS)
(contract-call? .sifcoin transfer bob u500000 none) ;; 0.5 SIF
```

### Using allowances

```clarity path=null start=null
(define-constant owner tx-sender)
(define-constant spender 'ST3J...SPENDER)

;; owner approves spender
(contract-call? .sifcoin approve spender u1000000)

;; later, spender calls transfer-from
(contract-call? .sifcoin transfer-from owner spender u200000 none)
```

## Deployment notes

- Update your desired network configuration in the `settings/*.toml` files.
- Use Clarinet’s `deployments` commands or your preferred Stacks deployment tooling to deploy `contracts/sifcoin.clar` to Testnet/Mainnet.
- Once deployed, the on-chain contract principal will be the **owner** that can call `mint`.

## Checking the project

To re-run the contract checks at any time:

```bash path=null start=null
clarinet check
```

Any syntax or type errors will be reported in the console so you can fix them before deployment.
