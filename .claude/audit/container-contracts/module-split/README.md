# 구현을 여러 파일로 쪼갤 수 있는가 — 실측

```bash
luau-analyze .claude/audit/container-contracts/module-split/naive/check.luau  # 5건 (체이닝 깨짐)
luau          .claude/audit/container-contracts/module-split/naive/check.luau  # 런타임 에러
luau-analyze .claude/audit/container-contracts/module-split/stub/check.luau   # 3건 (정상)
luau          .claude/audit/container-contracts/module-split/stub/check.luau   # 정상 동작
```

## 결론

**컨테이너 타입을 반환하는 메소드**(`Map`, `PushBack`, `Slice` …)는 그 타입이
선언된 곳과 **같은 모듈에서 보여야** 합니다. 두 가지 방법이 있습니다.

### ❌ naive — 쪼갠 파일이 데이터부만 앎

`Arr/Transform.luau` 가 `ArrData<T>` 만 알고 `ArrData<G>` 를 반환하면:

```
타입:   Key 'Map' not found in table 'ArrData<string>'
런타임: attempt to call missing method 'Map' of table
```

체이닝이 **타입과 런타임 양쪽에서** 깨집니다(반환 테이블에 메타테이블이 없음).

### ✅ stub — 계약 파일에 스텁을 두고 `typeof`

`Types.luau` 에 시그니처만 있는 스텁 함수를 두고 `typeof` 로 인터페이스를
만들면, 구현 파일이 `Types.Arr<T>` 를 가져다 쓸 수 있어 **컨테이너 타입을
반환할 수 있습니다.**

```
타입:   정확히 3건 (NEG 2 + CANARY)
추론:   chain: ArrData<number> & ArrIfce   ← 2단 타입 변환 체이닝 보존
런타임: 정상
```

quad 가 `quad-types` 에서 쓰는 방식입니다. **비용은 시그니처 중복** — 스텁
하나와 진짜 구현 하나를 둘 다 유지해야 합니다.

## 모듈 경계 너머 `typeof`

`typeof(OtherModule.fn)` 은 **완전히 동작합니다**(제네릭 포함). 위 naive 안이
깨진 건 `typeof` 때문이 아니라 반환 타입이 데이터부였기 때문입니다.

## require 경로 규칙 (실측)

| 어디서 | 폴더 **안** 형제 | 폴더 **밖** 형제 |
|---|---|---|
| `Foo/init.luau` | `@self/Bar` | **`./Types`** (`../Types` ❌) |
| `Foo/Bar.luau` | `./Baz` | **`../Types`** (`./Types` ❌) |

`init.luau` 가 곧 디렉터리 자신이라 거기서만 `.` 이 부모를 가리킵니다.
**같은 폴더 안에서도 파일에 따라 경로가 다릅니다.**
