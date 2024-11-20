#!/bin/bash
ACTIVE_ADDRESS=$(docker run --rm -v ./iota_config:/root/.iota/iota_config iotaledger/iota-tools:testnet /bin/sh -c "RUST_BACKTRACE=full /usr/local/bin/iota client active-address --json")
BALANCE_OUTPUT=$(docker run --rm -v ./iota_config:/root/.iota/iota_config iotaledger/iota-tools:testnet /bin/sh -c "RUST_BACKTRACE=full /usr/local/bin/iota client balance --json")

LARGEST_BALANCE_INFO=$(echo "$BALANCE_OUTPUT" | jq -r '.[0][0][1] | sort_by(.balance | tonumber) | reverse | .[0]')
COIN_OBJECT_ID=$(echo "$LARGEST_BALANCE_INFO" | jq -r '.coinObjectId')
BALANCE=$(echo "$LARGEST_BALANCE_INFO" | jq -r '.balance')

if [ -z "$COIN_OBJECT_ID" ]; then
    echo "Error: No coin object ID found. Please ensure you have coins available."
    exit 1
fi

echo "Using coin object ID: $COIN_OBJECT_ID with balance: $BALANCE"

if [ "$BALANCE" -lt 2000000000000000 ]; then
    echo "Error: Insufficient balance. Required: 2000000000000000, Current: $BALANCE"
    exit 1
fi

echo "Preparing gas token..."
docker run --rm -v ./iota_config:/root/.iota/iota_config iotaledger/iota-tools:testnet /bin/sh -c "/usr/local/bin/iota client transfer-iota --to ${ACTIVE_ADDRESS} --iota-coin-object-id ${COIN_OBJECT_ID} --amount 9000000000" 

sleep 2

echo "Sending request to be candidate..."
docker run --rm -v ./iota_config:/root/.iota/iota_config -v ./validator.info:/iota/validator.info iotaledger/iota-tools:testnet /bin/sh -c "/usr/local/bin/iota validator become-candidate /iota/validator.info"

sleep 2

echo "Staking token..."
docker run --rm -v ./iota_config:/root/.iota/iota_config iotaledger/iota-tools:testnet /bin/sh -c "iota client call --package 0x3 --module iota_system --function request_add_stake --args 0x5 ${COIN_OBJECT_ID} ${ACTIVE_ADDRESS} --gas-budget 10000000"

sleep 2

echo "Joining committee..."
docker run --rm -v ./iota_config:/root/.iota/iota_config -v ./validator.info:/iota/validator.info iotaledger/iota-tools:testnet /bin/sh -c "/usr/local/bin/iota validator join-committee"