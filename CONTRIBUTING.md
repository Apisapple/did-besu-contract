# Contribution Guidelines

이 문서는 본 저장소의 Diamond Proxy Pattern(EIP-2535) 기반 개발, 테스트, 업그레이드 기여 절차를 설명합니다.

## 1. 기본 원칙

- 모든 작업은 Issue 생성 후 시작합니다.
- 변경은 작고 명확한 단위로 나눕니다.
- 기능 변경 시 테스트와 문서를 함께 업데이트합니다.
- 기존 동작 호환성이 깨지는 경우, PR 설명에 명시합니다.

## 2. 아키텍처 개요

현재 프로젝트는 아래 구조를 사용합니다.

- Diamond Core
  - Diamond
  - DiamondCutFacet
  - DiamondLoupeFacet
  - OwnershipFacet
- OpenDID 기능 Facet
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

## 3. 개발 프로세스

1. Issue 생성
- 작업 목적, 배경, 영향 범위를 작성합니다.

2. 브랜치 생성
- 기준 브랜치: develop
- 브랜치 네이밍 예시
  - feature/diamond-<topic>
  - fix/facet-<topic>
  - chore/docs-<topic>

3. 구현
- Facet 단위로 변경합니다.
- 권한 로직은 기존 역할 정책(Admin/TAS/Issuer)을 유지합니다.
- selector 충돌 가능성이 있는 변경은 PR에서 반드시 설명합니다.

4. 검증
- 컴파일, 테스트, 필요 시 배포 스크립트 검증까지 완료합니다.

5. PR 제출
- 변경 목적, 구현 방법, 테스트 결과, 업그레이드 영향도를 포함합니다.

## 4. 로컬 개발 명령어

```bash
npm install
npx hardhat compile
npx hardhat test
```

배포 테스트:

```bash
npx hardhat run scripts/deploy-contract.js --network <network-name>
```

Facet 교체 예시 실행:

```bash
DIAMOND_ADDRESS=<diamond-address> npx hardhat run scripts/upgrade-contract.js --network <network-name>
```

## 5. Diamond 개발 규칙

1. Facet 변경 원칙
- 단일 책임 원칙을 유지합니다.
- 기능 추가는 기존 Facet 확장 또는 신규 Facet 추가로 처리합니다.
- 불필요한 cross-facet 의존을 피합니다.

2. 스토리지 원칙
- AppStorage 레이아웃을 임의 변경하지 않습니다.
- 스토리지 필드 순서와 타입 변경은 업그레이드 호환성 검토 후 진행합니다.
- 구조 변경 시 마이그레이션 전략을 PR에 포함합니다.

3. Selector 원칙
- 함수 시그니처 변경 시 기존 selector 영향도를 점검합니다.
- Replace/Add/Remove 대상 selector 목록을 PR 설명에 기록합니다.

4. 초기화 원칙
- 초기화는 OpenDIDInit 또는 명시적 init 함수에서만 처리합니다.
- 초기화 재진입, 중복 실행 방지를 검증합니다.

## 6. 테스트 가이드

필수 검증 항목:

- Diamond 배포 후 facet 등록 성공 여부
- 역할 기반 접근 제어 동작
- DID/VC/ZKP 핵심 기능 회귀 테스트
- facet 교체 후 기존 동작 유지 여부

권장 사항:

- 기능 추가 시 성공/실패 케이스를 모두 작성합니다.
- revert 메시지 또는 에러 타입을 명확히 검증합니다.

## 7. 업그레이드 가이드

1. 변경 Facet 구현 및 배포
2. 대상 selector 추출
3. diamondCut(Replace/Add/Remove) 실행
4. 후속 검증 테스트 실행

업그레이드 PR에는 아래를 반드시 포함합니다.

- 변경 Facet 목록
- 변경 selector 목록
- 기존 기능 호환성 영향
- 롤백 또는 복구 방안

## 8. 코드 리뷰 기준

리뷰는 아래 항목을 우선 확인합니다.

- 기능 정확성: 요구사항 충족 여부
- 안전성: 권한, 초기화, selector 충돌, 스토리지 호환성
- 테스트 완결성: 회귀 테스트 및 실패 케이스 포함 여부
- 문서 정합성: README/가이드/주석 업데이트 여부
- 변경 범위 적절성: 불필요한 리팩터링/대규모 혼합 변경 여부

## 9. PR 작성 가이드

PR 템플릿 권장 항목:

- Summary
- Related Issue
- Changes
- Diamond Cut Impact
- Test Result
- Backward Compatibility Notes

체크리스트 예시:

- [ ] npx hardhat compile 통과
- [ ] npx hardhat test 통과
- [ ] 문서 업데이트 완료
- [ ] 업그레이드 영향도 작성

## 10. 이슈/버그 리포트 가이드

버그 리포트에는 아래를 포함합니다.

- 재현 절차
- 기대 결과 / 실제 결과
- 네트워크 정보, 커밋 해시, 실행 명령어
- 관련 로그 또는 트랜잭션 정보

## 11. Coding Style / Commit / 문서 규칙

- Coding Style: OpenDID Coding Style
  - https://github.com/OmniOneID/did-doc-architecture/blob/main/docs/rules/coding_style.md
- Commit Rule: OpenDID Commit Rule
  - https://github.com/OmniOneID/did-doc-architecture/blob/main/docs/rules/git_code_commit_rule.md
- Document Guide: OpenDID Document Guide
  - https://github.com/OmniOneID/did-doc-architecture/blob/main/docs/guide/docs/write_document_guide.md

## 12. Code of Conduct / CLA / License

- Code of Conduct: CODE_OF_CONDUCT.md
- CLA: CLA.md
- License: Apache 2.0 (LICENSE)