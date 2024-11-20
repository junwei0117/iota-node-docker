#!/bin/bash

echo "Joining committee..."
docker run --rm -v ./iota_config:/root/.iota/iota_config -v ./validator.info:/iota/validator.info iotaledger/iota-tools:testnet /bin/sh -c "/usr/local/bin/iota validator join-committee"