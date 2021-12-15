#!/bin/bash
set -e

mv contracts my-starknet-sources

npx hardhat starknet-compile
npx hardhat starknet-deploy starknet-artifacts/my-starknet-sources/contract.cairo/ --starknet-network $1 --inputs 10
