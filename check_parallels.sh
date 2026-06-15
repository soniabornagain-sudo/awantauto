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

refresh_kakao_token() {
    local rest_api_key refresh_token client_secret
    rest_api_key=$(grep '^KAKAO_REST_API_KEY=' "$ENV_FILE" 2>/dev/null | cut -d'=' -f2)
    refresh_token=$(grep '^KAKAO_REFRESH_TOKEN=' "$ENV_FILE" 2>/dev/null | cut -d'=' -f2)
    client_secret=$(grep '^KAKAO_CLIENT_SECRET=' "$ENV_FILE" 2>/dev/null | cut -d'=' -f2)

    if [ -z "$rest_api_key" ] || [ -z "$refresh_token" ]; then
        echo "[WARN] KAKAO_REST_API_KEY 또는 KAKAO_REFRESH_TOKEN 없음 – 토큰 갱신 불가"
        return 1
    fi

    local response
    response=$(curl -s -X POST "https://kauth.kakao.com/oauth/token" \
        -d "grant_type=refresh_token" \
        -d "client_id=$rest_api_key" \
        -d "client_secret=$client_secret" \
        -d "refresh_token=$refresh_token")

    local new_access_token new_refresh_token
    new_access_token=$(echo "$response" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('access_token',''))" 2>/dev/null)
    new_refresh_token=$(echo "$response" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('refresh_token',''))" 2>/dev/null)

    if [ -z "$new_access_token" ]; then
        echo "[WARN] 새 access_token 발급 실패 – 응답: $response"
        return 1
    fi

    sed -i '' "s|^KAKAO_ACCESS_TOKEN=.*|KAKAO_ACCESS_TOKEN=$new_access_token|" "$ENV_FILE"
    if [ -n "$new_refresh_token" ]; then
        sed -i '' "s|^KAKAO_REFRESH_TOKEN=.*|KAKAO_REFRESH_TOKEN=$new_refresh_token|" "$ENV_FILE"
        echo "[카카오] access_token + refresh_token 갱신 완료"
    else
        echo "[카카오] access_token 갱신 완료"
    fi
    return 0
}

_send_kakao_once() {
    local token="$1" message="$2"
    local template
    template=$(printf '{"object_type":"text","text":"%s","link":{"web_url":"https://onewms.co.kr","mobile_web_url":"https://onewms.co.kr"}}' "$message")
    curl -s -o /dev/null -w "%{http_code}" -X POST "https://kapi.kakao.com/v2/api/talk/memo/default/send" \
        -H "Authorization: Bearer $token" \
        --data-urlencode "template_object=$template"
}

send_kakao() {
    local message="$1"
    local token
    token=$(grep '^KAKAO_ACCESS_TOKEN=' "$ENV_FILE" 2>/dev/null | cut -d'=' -f2)
    if [ -z "$token" ]; then
        echo "[WARN] KAKAO_ACCESS_TOKEN 없음 – 카카오 알림 건너뜀"
        return
    fi

    local http_code
    http_code=$(_send_kakao_once "$token" "$message")

    if [ "$http_code" = "401" ]; then
        echo "[카카오] 토큰 만료(401) – 자동 갱신 시도..."
        if refresh_kakao_token; then
            token=$(grep '^KAKAO_ACCESS_TOKEN=' "$ENV_FILE" | cut -d'=' -f2)
            http_code=$(_send_kakao_once "$token" "$message")
        else
            echo "[WARN] 토큰 갱신 실패 – 전송 건너뜀"
            return 1
        fi
    fi

    if [ "$http_code" = "200" ]; then
        echo "[카카오] 전송 완료: $message"
    else
        echo "[WARN] 카카오 전송 실패 – HTTP $http_code: $message"
        return 1
    fi
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
    # 일정 횟수까지 VM이 안 뜨면 .pvm 파일을 다시 open 시도 (기동 실패 대비)
    if [ "$i" -eq 5 ] || [ "$i" -eq 10 ]; then
        echo "[재시도] ${i}번째까지 VM 미감지 – .pvm 다시 열기: $VM_PVM"
        open "$VM_PVM"
    fi
done

echo "[오류] Windows VM이 60초 내에 시작되지 않았습니다" >&2
exit 1
