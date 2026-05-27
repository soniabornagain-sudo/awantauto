# 어원트 발주 자동화

Playwright 기반 OneWMS 발주 자동화 + 카카오톡 알림 시스템.
Mac + Parallels Windows VM 환경에서 PM2 크론으로 매일 자동 실행됩니다.

---

## 전체 흐름

```
오후 2:05  check_parallels.sh   Parallels Desktop 실행 + Windows VM 깨우기
오후 2:10  (Windows 자동)       오토핫키가 OneSync 자동화 실행
오후 2:20  onewms_checker.py    OneWMS 로그인 → 발주 → 카카오톡 알림
오후 3:00  stop_parallels.sh    Windows VM 종료 + Parallels Desktop 닫기
  ↓
다음날 오후 2:05 → 다시 반복 (평일 기준)
```

---

## PM2 스케줄 구성

| PM2 앱 이름 | 크론 | 역할 |
|---|---|---|
| `onewms-checker` | `20 14 * * 1-5` | `check_parallels.sh` → `onewms_checker.py` 순서 실행 |
| `parallels-stopper` | `0 15 * * 1-5` | `stop_parallels.sh` 실행 |

> `onewms-checker`의 2:05 VM 웨이크업은 Windows 측 오토핫키 또는 별도 스케줄러로 관리합니다.

---

## 설치 방법

### 1. 저장소 클론

```bash
git clone https://github.com/soniabornagain-sudo/awantauto.git
cd awantauto
```

### 2. `.env` 파일 생성

```bash
cp .env.example .env  # 또는 직접 생성
```

아래 환경변수를 채워넣습니다 (환경변수 목록은 아래 참고).

### 3. 환경 설치 및 PM2 등록

```bash
bash setup.sh
```

`setup.sh`가 수행하는 작업:
- `pip3 install -r requirements.txt`
- `playwright install chromium`
- `logs/` 디렉토리 생성
- PM2에 스케줄 등록 + `pm2 save`

### 4. 카카오 토큰 발급

카카오 디벨로퍼스에서 앱을 생성하고 OAuth 인증으로 `access_token` / `refresh_token`을 발급받아 `.env`에 입력합니다.
토큰 만료 시 스크립트가 `refresh_token`으로 자동 갱신합니다.

---

## 필요한 환경변수 (`.env`)

| 변수명 | 설명 |
|---|---|
| `ONEWMS_ACCOUNT` | OneWMS 회사 계정 코드 |
| `ONEWMS_USERNAME` | OneWMS 로그인 아이디 |
| `ONEWMS_PASSWORD` | OneWMS 로그인 비밀번호 |
| `KAKAO_ACCESS_TOKEN` | 카카오 나에게 메시지 전송용 액세스 토큰 |
| `KAKAO_REFRESH_TOKEN` | 액세스 토큰 자동 갱신용 리프레시 토큰 |
| `KAKAO_REST_API_KEY` | 카카오 앱 REST API 키 |
| `KAKAO_CLIENT_SECRET` | 카카오 앱 Client Secret (선택) |

---

## 유용한 명령어

```bash
pm2 list                        # 등록된 프로세스 목록
pm2 logs onewms-checker         # 실시간 로그
pm2 logs parallels-stopper      # 종료 스크립트 로그
python3 onewms_checker.py       # 즉시 테스트 실행
pm2 stop onewms-checker         # 스케줄 일시 중단
pm2 delete onewms-checker       # 스케줄 삭제
```

---

## 파일 구조

```
onewms-auto/
├── onewms_checker.py      # OneWMS 발주 자동화 + 카카오톡 알림
├── check_parallels.sh     # Parallels + Windows VM 깨우기
├── stop_parallels.sh      # Windows VM 종료 + Parallels 닫기
├── ecosystem.config.js    # PM2 크론 스케줄 설정
├── setup.sh               # 최초 환경 설치 스크립트
├── requirements.txt       # Python 패키지 목록
└── .env                   # 환경변수 (git 제외)
```
