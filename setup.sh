#!/usr/bin/env bash
set -e

echo "=== OneWMS 자동화 환경 설치 ==="

# 1. Python 의존성
echo "[1] pip 패키지 설치..."
pip3 install -r requirements.txt

# 2. Playwright 브라우저 (Chromium)
echo "[2] Playwright Chromium 설치..."
python3 -m playwright install chromium

# 3. 로그 디렉토리
mkdir -p logs

# 4. pm2 설치 확인
if ! command -v pm2 &>/dev/null; then
  echo "[3] pm2 설치 중 (npm 필요)..."
  npm install -g pm2
else
  echo "[3] pm2 이미 설치됨: $(pm2 --version)"
fi

# 5. pm2 등록
echo "[4] pm2 스케줄 등록..."
pm2 start ecosystem.config.js
pm2 save

echo ""
echo "=== 설치 완료 ==="
echo "※ .env 파일에 KAKAO_ACCESS_TOKEN 을 입력한 뒤 'pm2 restart onewms-checker' 를 실행하세요."
echo ""
echo "유용한 명령어:"
echo "  pm2 list                      # 등록된 프로세스 목록"
echo "  pm2 logs onewms-checker       # 실시간 로그 확인"
echo "  python3 onewms_checker.py     # 즉시 테스트 실행"
echo "  pm2 stop onewms-checker       # 스케줄 일시 중단"
echo "  pm2 delete onewms-checker     # 스케줄 삭제"
