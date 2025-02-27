#!/bin/bash
set -e

CONFIG_FILE_NAME="hardhat.config.ts"

# setup example repo
rm -rf starknet-hardhat-example
git clone -b plugin --single-branch git@github.com:Shard-Labs/starknet-hardhat-example.git
cd starknet-hardhat-example
git log -n 1
npm install

# used by some cases
../scripts/setup-venv.sh

total=0
success=0

test_dir="../test/$TEST_SUBDIR"

if [ ! -d "$test_dir" ]; then
    echo "Invalid test directory"
    exit -1
fi

function iterate_dir(){
    network="$1"
    echo "Starting tests on $network"
    for test_case in "$test_dir"/*; do
        test_name=$(basename $test_case)

        # Skip if there is a network file that doesn't specify the current network.
        # So by default, if no network.json, proceed with testing on the current network.
        network_file="$test_case/network.json"
        if [[ -f "$network_file" ]] && [[ $(jq ".$network" "$network_file") != true ]]; then
            echo "Skipping $network test for $test_name"
            continue
        fi

        total=$((total + 1))
        echo "Test $total) $test_name"

        config_file_path="$test_case/$CONFIG_FILE_NAME"
        if [ ! -f "$config_file_path" ]; then
            echo "Error: No config file provided!"
            continue
        fi

        # replace the dummy config (CONFIG_FILE_NAME) with the one used by this test
        /bin/cp "$config_file_path" "$CONFIG_FILE_NAME"

        NETWORK="$network" "$test_case/check.sh" && success=$((success + 1)) || echo "Test failed!"

        rm -rf starknet-artifacts
        git checkout --force
        git clean -fd
        echo "----------------------------------------------"
        echo
    done
    echo "Finished tests on $network"
}

# perform tests on Alpha-goerli testnet only on master branch and in a linux environment
if [[ "$CIRCLE_BRANCH" == "master" ]] && [[ "$OSTYPE" == "linux-gnu"* ]]; then
    iterate_dir alpha
fi

# install, build and run devnet
export PATH="$PATH:/opt/circleci/.pyenv/shims:/usr/local/bin"
which starknet-devnet || ../scripts/install-devnet.sh
echo "starknet-devnet at: $(which starknet-devnet)"
starknet-devnet & # assuming the default (localhost:5000)
iterate_dir devnet

echo "Tests passing: $success / $total"
exit $((total - success))
