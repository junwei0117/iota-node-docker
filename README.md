# IOTA Validator Setup Guide - Testnet

This guide walks you through the essential steps to set up an IOTA validator node.\

## Required Network Ports

Ensure the following ports are open in your firewall:

| Port       | Reachability      | Purpose                           |
|------------|-------------------|-----------------------------------|
| TCP/8080   | inbound          | protocol/transaction interface     |
| TCP/8081   | inbound/outbound | primary interface                 |
| UDP/8084   | inbound/outbound | peer to peer state sync interface |
| TCP/8443   | outbound         | metrics pushing                   |
| TCP/9184   | localhost        | metrics scraping                  |

> **Note**: Maybe you already noticed that port 8081 is using TCP, which conflicts with docs.iota.org and validator.info as well. This is a known bug, but the node is actually communicating via TCP.

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

### 6. Start Your Validator Node

```bash
docker compose up -d
docker compose logs -f
```

### 7. Register as a Validator Candidate

We will obtain some tokens from the faucet for gas fees.

```bash
./become_candidate.sh
```

### 8. Request Delegation from IOTA Foundation

1. Get your validator address by running:

```bash
docker run --rm -v ./iota_config:/root/.iota/iota_config iotaledger/iota-tools:testnet  /bin/sh -c "/usr/local/bin/iota client active-address"
```

2. Copy the output address
3. Contact the IOTA Foundation with your validator address

### 9. Join the committee

Before joining the committee, ensure:
- Your node is fully synced with the network
- IOTA Foundation has already delegated the staking tokens for your validator

Once your node is ready, submit your request to join the committee:

```bash
./join_committee.sh
```

### 10. Monitor Validator Status

```bash
docker run --rm -v ./iota_config:/root/.iota/iota_config iotaledger/iota-tools:testnet /bin/sh -c "/usr/local/bin/iota validator display-metadata" | grep status
```

You should see your node's status is `pending` now, it will become active and join the committee starting from next epoch.

```
<YOUR-VALUDATOR_ADDRESS>'s validator status: Pending
```
