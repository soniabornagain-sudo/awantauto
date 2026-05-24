# 3PL 발주 자동화 시스템

## 프로젝트 개요

OneSync(Windows)와 OneWMS(웹)를 자동화하는 3PL 발주 자동화 시스템.
맥 미니에서 24시간 상시 실행되며, 평일 오후 순서대로 두 단계가 자동으로 동작한다.

---

## 기술 스택

| 역할 | 기술 |
|------|------|
| OneSync 자동화 | Parallels + Windows + AutoHotkey |
| OneWMS 웹 자동화 | Python 3.9 + Playwright (Chromium headless) |
| 스케줄 관리 | PM2 |
| 완료 알림 | 카카오톡 API (나에게 메시지 전송) |

---

## 실행 흐름

```
[오후 2:10] OneSync (Windows / AutoHotkey)
  └─ 취소 적용 → 주문 수집 → 프로그램 종료

[오후 2:20] OneWMS (Python / Playwright)
  └─ 로그인
  └─ 주문배송관리 → 발주 관리 → 발주 클릭
  └─ 다음 버튼 3회 클릭 (클릭마다 20초 대기)
  └─ '발주가 완료되었습니다.' 팝업 처리
  │    ├─ Bootstrap 모달이면 확인 버튼 클릭
  │    └─ 브라우저 기본 alert이면 page.on("dialog")로 자동 수락
  └─ 카카오톡 알림 전송: "발주 완료되었습니다 ✅"
       (팝업 종류와 무관하게 이 단계까지 도달하면 항상 전송)
```

---

## 설치 방법

### 1. 저장소 준비

```bash
cd ~/onewms-auto
```

### 2. 환경변수 설정

`.env` 파일에 아래 항목을 입력한다.

```env
ONEWMS_ACCOUNT=<계정명>
ONEWMS_USERNAME=<아이디>
ONEWMS_PASSWORD=<비밀번호>
KAKAO_ACCESS_TOKEN=<액세스 토큰>
KAKAO_REFRESH_TOKEN=<리프레시 토큰>
KAKAO_REST_API_KEY=<REST API 키>
KAKAO_CLIENT_SECRET=<Client Secret>
```

### 3. 자동 설치 및 PM2 등록

```bash
bash setup.sh
```

내부 동작:
- pip 패키지 설치 (`playwright`, `requests`, `python-dotenv`)
- Playwright Chromium 브라우저 설치
- PM2가 없으면 npm으로 자동 설치
- `ecosystem.config.js` 기반으로 PM2 스케줄 등록 및 저장

---

## 주요 파일 설명

```
onewms-auto/
├── onewms_checker.py     # 메인 자동화 스크립트
├── .env                  # 계정 정보 및 카카오 토큰 (버전 관리 제외)
├── requirements.txt      # Python 패키지 목록
├── ecosystem.config.js   # PM2 스케줄 설정 (평일 14:20 실행)
├── setup.sh              # 전체 환경 설치 스크립트
└── SKILL.md              # 프로젝트 문서 (이 파일)
```

### onewms_checker.py 주요 함수

| 함수 | 설명 |
|------|------|
| `_get_token()` | `.env`에서 액세스 토큰 로드 |
| `_refresh_access_token()` | 토큰 만료 시 refresh_token으로 자동 갱신, `.env` 업데이트 |
| `send_kakao_message()` | 카카오톡 전송, 401 오류 시 자동 갱신 후 재시도 |
| `run()` | 전체 자동화 흐름 실행 (로그인 → 발주 → 알림) |

---

## 트러블슈팅

### 다음 버튼을 못 찾는 경우
- 셀렉터: `button.btn-primary` + 텍스트 `^다` (실제 버튼 텍스트가 `다 음`으로 공백 포함)
- 페이지 로딩이 느릴 경우 클릭 간 대기 시간(현재 20초)을 늘린다.

### 발주 메뉴 클릭이 잘못 매칭되는 경우
- `text=발주`는 `발주 관리`도 매칭되므로 `a[class*='depth-8']` + 정규식 `^발주$`로 정확히 지정한다.

### 카카오톡 401 오류
- 액세스 토큰 만료 → `_refresh_access_token()`이 자동으로 새 토큰 발급 후 `.env` 갱신
- refresh_token까지 만료된 경우 카카오 개발자 콘솔에서 재발급 후 `.env`에 직접 입력

### PM2 스케줄 적용 후 실행 안 될 때
```bash
pm2 restart onewms-checker
pm2 logs onewms-checker
```

### 수동 즉시 실행
```bash
python3 ~/onewms-auto/onewms_checker.py
```
