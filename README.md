# IOTA Validator Setup Guide

This guide walks you through the essential steps to set up an IOTA validator node.\

## Setup Steps

### 1. Download Configuration Template

Download the validator configuration file template:

```bash
curl -o validator.yaml https://docs.iota.org/assets/files/validator-f8117cabc760058cd9c133360cfa455f.yaml
```

### 2. Add Account Key Pairs

Configure your validator's account key pair in the `validator.yaml` file, we will use a script to generate key pairs later

```yaml
account-key-pair:
  path: /opt/iota/key-pairs/account.key
```

### 3. Configure P2P Settings

Configure the P2P settings in your `validator.yaml` file by following these steps:

1. Update the external address:
```yaml
p2p-config:
  external-address: /dns/<YOUR-DOMAIN>/udp/8084
```
> **Note**: Replace `<YOUR-DOMAIN>` with your validator's public domain name. This address must be accessible from the internet.

2. Add the seed peers configuration:
```yaml
p2p-config:
  listen-address: "0.0.0.0:8084"
  external-address: /dns/<YOUR-DOMAIN>/udp/8084
  anemo-config:
    max-concurrent-connections: 0
  seed-peers:
    - address: /dns/access-0.r.testnet.iota.cafe/udp/8084
      peer-id: 46064108d0b689ed89d1f44153e532bb101ce8f8ca3a3d01ab991d4dea122cfc
    - address: /dns/access-1.r.testnet.iota.cafe/udp/8084
      peer-id: 8ffd25fa4e86c30c3f8da7092695e8a103462d7a213b815d77d6da7f0a2a52f5
```

### 4. Download Genesis Block

```bash
curl -fLJO https://dbfiles.testnet.iota.cafe/genesis.blob
```

### 5. Make validator.info and Generate Validator Keys

Generate the necessary key pairs for your validator, the key pairs will be stored in `key-pairs` folder.

```bash
./generate_validator_info.sh
```

> **Important**: Back up your generated keys securely. Loss of these keys could result in loss of access to your validator.

### 6. Run your node up

```bash
docker compose up -d
```

### 7. After your node is fully sync and running, you can send request to join the committee

```bash
./join_committee.sh
```