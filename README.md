# TimeMachine Cleaner

개인용 macOS Time Machine 로컬 스냅샷 정리 앱입니다.

## 기능

- 현재 Mac의 Time Machine 로컬 스냅샷 조회
- 내장 SSD의 전체·사용·여유 용량 표시
- 개별 또는 전체 선택
- 삭제 전 확인
- macOS 관리자 인증 후 선택 항목만 삭제
- 삭제 전후 여유 공간을 비교해 실제 확보 용량 표시
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

APFS 스냅샷은 현재 파일시스템 및 다른 스냅샷과 저장 블록을 공유합니다. macOS 명령이 스냅샷별 독립 크기를 제공하지 않으므로 삭제 전 개별 크기는 표시하지 않고, 삭제 후 실제 여유 공간 증가량을 표시합니다.
