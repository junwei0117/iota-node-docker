#!/bin/bash

if [ ! -f "./key-pairs/authority.key" ]; then
    echo "Error: authority.key file not found in key-pairs directory"
    exit 1
fi

echo "Updating Authority Key..."
docker run --rm -v ./iota_config:/root/.iota/iota_config -v ./key-pairs:/iota/key-pairs iotaledger/iota-tools:testnet /bin/sh -c "/usr/local/bin/iota validator update-metadata authority-pub-key /iota/key-pairs/authority.key "
