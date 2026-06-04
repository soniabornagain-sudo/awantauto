#!/bin/bash

VM_PVM="$HOME/Parallels/Windows 11.pvm"
ENV_FILE="$(dirname "$0")/.env"

# Parallels Desktop 업데이트 팝업 자동 닫기 (다음에 묻기 클릭)
dismiss_update_popup() {
    osascript <<'EOF' 2>/dev/null
tell application "System Events"
    if not (exists process "Parallels Desktop") then return false
    tell process "Parallels Desktop"
        repeat with w in windows
            repeat with b in buttons of w
                set bName to name of b
                if bName contains "다음에 묻기" or bName contains "Remind Me Later" or bName contains "Later" then
                    click b
                    return true
                end if
            end repeat
        end repeat
    end tell
end tell
return false
EOF
}

send_kakao() {
    local message="$1"
    local token
    token=$(grep '^KAKAO_ACCESS_TOKEN=' "$ENV_FILE" 2>/dev/null | cut -d'=' -f2)
    if [ -z "$token" ]; then
        echo "[WARN] KAKAO_ACCESS_TOKEN 없음 – 카카오 알림 건너뜀"
        return
    fi
    local template
    template=$(printf '{"object_type":"text","text":"%s","link":{"web_url":"https://onewms.co.kr","mobile_web_url":"https://onewms.co.kr"}}' "$message")
    curl -s -X POST "https://kapi.kakao.com/v2/api/talk/memo/default/send" \
        -H "Authorization: Bearer $token" \
        --data-urlencode "template_object=$template" \
        > /dev/null
    echo "[카카오] 전송 완료: $message"
}

echo "[시작] check_parallels.sh 실행됨 – $(date '+%Y-%m-%d %H:%M:%S')"

# VM 프로세스가 이미 실행 중이면 종료
if pgrep -x "prl_vm_app" > /dev/null; then
    echo "[완료] VM이 이미 실행 중 – 추가 작업 없음"
    send_kakao "1단계: Parallels + Windows 기동 완료 ✅"
    exit 0
fi

echo "[Parallels] .pvm 파일 열기 시작 – $VM_PVM"
open "$VM_PVM"
echo "[Parallels] open 명령 실행 완료 – VM 기동 대기 중..."

# VM 프로세스 뜰 때까지 최대 60초 대기, 매 루프마다 업데이트 팝업 확인
for i in $(seq 1 12); do
    sleep 5
    dismiss_update_popup > /dev/null 2>&1
    if pgrep -x "prl_vm_app" > /dev/null; then
        echo "[VM] Windows VM 프로세스 감지됨 (${i}번째 확인, $((i * 5))초 경과)"
        echo "[완료] VM 기동 성공"
        send_kakao "1단계: Parallels + Windows 기동 완료 ✅"
        exit 0
    fi
    echo "[대기] VM 미감지 – ${i}/12 (${i}번째 확인, $((i * 5))초 경과)"
done

echo "[오류] Windows VM이 60초 내에 시작되지 않았습니다" >&2
exit 1
