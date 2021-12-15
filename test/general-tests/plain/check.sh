#!/bin/bash
set -e

INITIAL_VALUE=10
PUBLIC_KEY=1628448741648245036800002906075225705100596136133912895015035902954123957052

npx hardhat starknet-compile
npx hardhat starknet-deploy starknet-artifacts/contracts/contract.cairo/ --starknet-network $1 --inputs "$INITIAL_VALUE"
npx hardhat starknet-deploy starknet-artifacts/contracts/auth_contract.cairo/ --inputs "$PUBLIC_KEY $INITIAL_VALUE" --starknet-network $1
npx hardhat test test/sample-test.ts
