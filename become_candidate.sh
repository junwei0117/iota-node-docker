#!/bin/bash

echo "Requesting gas fee from faucet..."
docker run --rm -v ./iota_config:/root/.iota/iota_config iotaledger/iota-tools:testnet /bin/sh -c "/usr/local/bin/iota client faucet --url https://faucet.testnet.iota.cafe/v1/gas --json"

sleep 2

echo "Sending request to be candidate..."
docker run --rm -v ./iota_config:/root/.iota/iota_config -v ./validator.info:/iota/validator.info iotaledger/iota-tools:testnet /bin/sh -c "/usr/local/bin/iota validator become-candidate /iota/validator.info"