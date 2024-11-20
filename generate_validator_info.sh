#!/bin/bash

if ! command -v jq &> /dev/null; then
    echo "jq is not installed. Installing jq..."
    apt update && apt install -y jq
fi

if [ -d "./key-pairs" ]; then
    read -p "Key Pairs Directory already exists. This will overwrite everything? [y/N] " response
    if [[ ! $response =~ ^[Yy]$ ]]; then
        echo "Operation cancelled"
        exit 1
    fi
    
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    BACKUP_DIR="key-pairs_backup_${TIMESTAMP}"
    cp -r ./key-pairs "${BACKUP_DIR}"
    rm -r ./key-pairs
fi

mkdir -p ./key-pairs
mkdir -p ./iota_config
mkdir -p ./tmp/key-pairs-for-making-info

KEYGEN_OUTPUT=$(docker run --rm iotaledger/iota-tools:testnet /bin/sh -c '/usr/local/bin/iota keytool generate ed25519 --json && cat *.key')

JSON_PART=$(echo "$KEYGEN_OUTPUT" | head -n-1)

IOTA_ADDRESS=$(echo "$JSON_PART" | jq -r '.iotaAddress')
PUBLIC_KEY=$(echo "$JSON_PART" | jq -r '.publicBase64Key')
ACCOUNT_BECH32_PRIVATE_KEY=$(echo "$KEYGEN_OUTPUT" | tail -n1)

cat > ./iota_config/client.yaml << EOF
---
keystore:
  File: /root/.iota/iota_config/iota.keystore
envs:
  - alias: custom
    rpc: "https://api.iota-rebased-alphanet.iota.cafe"
    ws: ~
    basic_auth: ~
active_env: custom
active_address: "${IOTA_ADDRESS}"
EOF

cat > ./iota_config/iota.aliases << EOF
[
  {
    "alias": "flamboyant-hematite", 
    "public_key_base64": "${PUBLIC_KEY}"
  }
]
EOF

cat > ./iota_config/iota.keystore << EOF
[ 
    "${ACCOUNT_BECH32_PRIVATE_KEY}"
]
EOF

read -p "Enter validator name: " NAME
read -p "Enter validator description: " DESCRIPTION
read -p "Enter image URL (press enter for default): " IMAGE_URL
read -p "Enter project URL (press enter for default): " PROJECT_URL
read -p "Enter hostname: " HOST_NAME

# Set defaults if empty
IMAGE_URL=${IMAGE_URL:-""}
PROJECT_URL=${PROJECT_URL:-""}

docker run --rm -v ./iota_config:/root/.iota/iota_config -v ./tmp/key-pairs-for-making-info:/iota iotaledger/iota-tools:testnet /bin/sh -c "RUST_BACKTRACE=full /usr/local/bin/iota validator make-validator-info \"$NAME\" \"$DESCRIPTION\" \"$IMAGE_URL\" \"$PROJECT_URL\" \"$HOST_NAME\" 1000"

PROTOCOL_PRIVATE_KEY=$(cat ./tmp/key-pairs-for-making-info/protocol.key)
docker run --rm iotaledger/iota-tools:testnet /bin/sh -c "/usr/local/bin/iota keytool convert $PROTOCOL_PRIVATE_KEY --json" | \
    grep '"base64WithFlag":' | cut -d'"' -f4 > ./key-pairs/protocol.key

ACCOUNT_PRIVATE_KEY=$(cat ./tmp/key-pairs-for-making-info/account.key)
docker run --rm iotaledger/iota-tools:testnet /bin/sh -c "/usr/local/bin/iota keytool convert $ACCOUNT_PRIVATE_KEY --json" | \
    grep '"base64WithFlag":' | cut -d'"' -f4 > ./key-pairs/account.key

NETWORK_PRIVATE_KEY=$(cat ./tmp/key-pairs-for-making-info/network.key)
docker run --rm iotaledger/iota-tools:testnet /bin/sh -c "/usr/local/bin/iota keytool convert $NETWORK_PRIVATE_KEY --json" | \
    grep '"base64WithFlag":' | cut -d'"' -f4 > ./key-pairs/network.key

docker run --rm iotaledger/iota-tools:testnet /bin/sh -c '/usr/local/bin/iota keytool generate bls12381 --json && cat *.key' | \
    tail -n1 > ./key-pairs/authority.key 2>/dev/null

mv ./tmp/key-pairs-for-making-info/validator.info .

echo "Your validator address is ${IOTA_ADDRESS}"

rm -rf tmp