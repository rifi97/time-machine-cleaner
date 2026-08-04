# TimeMachine Cleaner

개인용 macOS Time Machine 로컬 스냅샷 정리 앱입니다.

## 기능

- 현재 Mac의 Time Machine 로컬 스냅샷 조회
- 개별 또는 전체 선택
- 삭제 전 확인
- macOS 관리자 인증 후 선택 항목만 삭제
- 외장 Time Machine 백업은 변경하지 않음

## 요구 사항

- macOS 13 이상
- Swift 6 / Xcode 16 이상으로 소스 빌드 가능

## 빌드 및 테스트

```sh
swift test
swift build -c release
```

앱은 `/usr/bin/tmutil`로 목록을 읽고, 삭제 시 macOS 표준 관리자 인증 창을 표시합니다. 삭제 대상으로 허용되는 값은 `yyyy-MM-dd-HHmmss` 형식으로 제한됩니다.
