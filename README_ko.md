# DID Besu Contract

did-besu-contract는 OpenDID EVM 스마트 컨트랙트 프로젝트로, DID 문서, VC 메타데이터, ZKP 관련 스키마를 관리합니다.

현재 프로젝트는 Diamond Proxy Pattern(EIP-2535) 기반으로 구성되어 있습니다.

## S/W 사양

- 스마트 컨트랙트: Solidity 0.8.27
- 개발 환경: Hardhat 2.22.19+, Node.js 22.12.0+
- 블록체인 네트워크: Ethereum 호환 네트워크(Besu 포함)

## 아키텍처

컨트랙트는 Diamond 코어와 OpenDID 기능 Facet으로 분리되어 있습니다.

- Diamond 코어
  - Diamond
  - DiamondCutFacet
  - DiamondLoupeFacet
  - OwnershipFacet
- OpenDID Facet
  - OpenDIDAdminFacet
  - OpenDIDDidFacet
  - OpenDIDVcFacet
  - OpenDIDZKPFacet
- 초기화 컨트랙트
  - OpenDIDInit
- 외부 저장소 컨트랙트
  - DocumentStorage
  - VcMetaStorage
  - ZKPStorage

## 주요 기능

- DID 문서 등록, 조회, 상태 변경
- VC 메타데이터 및 VC 스키마 관리
- ZKP 스키마 및 Credential Definition 관리
- Admin/TAS/Issuer 기반 권한 제어
- Diamond Cut 기반 Facet 업그레이드

## 설치

```bash
npm install
```

## 컴파일

```bash
npx hardhat compile
```

## 테스트

```bash
npx hardhat test
```

## 배포 (Diamond)

```bash
npx hardhat run scripts/deploy-contract.js --network <network-name>
```

배포 스크립트는 다음 순서로 동작합니다.

1. Storage 컨트랙트와 MultibaseContract 배포
2. DiamondCutFacet 및 Diamond 코어 배포
3. 나머지 Facet을 diamondCut으로 등록
4. OpenDIDInit으로 앱 스토리지 초기화

## 업그레이드 (Facet 교체 예시)

```bash
DIAMOND_ADDRESS=<diamond-address> npx hardhat run scripts/upgrade-contract.js --network <network-name>
```

예시 스크립트는 OpenDIDVcFacet selector를 교체합니다.

## 디렉토리 구조

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

## 참고 링크

- Hardhat: https://hardhat.org
- Solidity 0.8.27 문서: https://docs.soliditylang.org/en/v0.8.27/
- Besu 문서: https://besu.hyperledger.org
