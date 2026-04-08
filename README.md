# DID Besu Contract

did-besu-contract is an OpenDID EVM smart contract project for managing DID Documents, VC metadata, and ZKP-related schemas.

The project now uses the Diamond Proxy Pattern (EIP-2535) for modular upgrades.

## Software Specs

- Smart contract: Solidity 0.8.27
- Development: Hardhat 2.22.19+, Node.js 22.12.0+
- Network: Ethereum-compatible chain (including Besu)

## Architecture

The contract is split into Diamond core and OpenDID feature facets.

- Diamond core
  - Diamond contract
  - DiamondCutFacet
  - DiamondLoupeFacet
  - OwnershipFacet
- OpenDID facets
  - OpenDIDAdminFacet
  - OpenDIDDidFacet
  - OpenDIDVcFacet
  - OpenDIDZKPFacet
- Init contract
  - OpenDIDInit
- External storage contracts
  - DocumentStorage
  - VcMetaStorage
  - ZKPStorage

## Main Features

- DID Document registration, retrieval, and status updates
- VC metadata and schema management
- ZKP schema and credential definition management
- Role-based authorization for Admin, TAS, and Issuer flows
- Facet-level upgrades via Diamond Cut

## Install

```bash
npm install
```

## Compile

```bash
npx hardhat compile
```

## Test

```bash
npx hardhat test
```

## Deploy (Diamond)

```bash
npx hardhat run scripts/deploy-contract.js --network <network-name>
```

This script deploys:

1. Storage contracts and MultibaseContract
2. DiamondCutFacet and Diamond core
3. Remaining facets through diamondCut
4. OpenDIDInit for app storage initialization

## Upgrade (Facet Replace Example)

```bash
DIAMOND_ADDRESS=<diamond-address> npx hardhat run scripts/upgrade-contract.js --network <network-name>
```

The example script replaces selectors of OpenDIDVcFacet.

## Project Structure

```plaintext
did-besu-contract
├── contracts/
│   ├── crypto/
│   ├── data/
│   ├── diamond/
│   │   ├── facets/
│   │   ├── interfaces/
│   │   ├── libraries/
│   │   ├── Diamond.sol
│   │   └── OpenDIDInit.sol
│   ├── storage/
│   └── utils/
├── scripts/
├── test/
├── data/
└── doc/
```

## References

- Hardhat: https://hardhat.org
- Solidity 0.8.27 docs: https://docs.soliditylang.org/en/v0.8.27/
- Besu docs: https://besu.hyperledger.org
