#!/bin/bash

VM_NAME="Windows 11"
WINDOWS_USER="${WINDOWS_USER:-Administrator}"

# Parallels VM 정보에서 IP 자동 감지
get_windows_ip() {
    arp -a 2>/dev/null \
        | grep -i "10.211.55" \
        | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' \
        | head -1
}

# Windows VM 종료 (prl_vm_app 실행 중일 때만)
if pgrep -x "prl_vm_app" > /dev/null; then
    echo "[1] Windows VM 종료 중..."

    WINDOWS_IP=$(get_windows_ip)

    if [ -n "$WINDOWS_IP" ]; then
        echo "[1] Windows IP: $WINDOWS_IP - SSH로 shutdown /s /t 0 전송..."
        if ssh -o ConnectTimeout=10 \
               -o StrictHostKeyChecking=no \
               -o BatchMode=yes \
               "$WINDOWS_USER@$WINDOWS_IP" \
               "shutdown /s /t 0" 2>/dev/null; then
            echo "[1] SSH 종료 명령 전송 완료, 종료 대기 (30s)..."
            sleep 30
        else
            echo "[1] SSH 실패"
        fi
    else
        echo "[1] Windows IP 감지 실패"
    fi

    echo "[1] Windows VM 종료 완료"
else
    echo "[1] VM이 이미 꺼져 있음 (오토핫키 종료됨) - Parallels Desktop만 종료"
fi

# Parallels Desktop 종료 (항상 실행)
if pgrep -x "prl_client_app" > /dev/null; then
    echo "[2] Parallels Desktop 종료 중..."
    osascript -e 'quit app "Parallels Desktop"'
    sleep 5
    echo "[2] Parallels Desktop 종료 완료"
else
    echo "[2] Parallels Desktop이 이미 꺼져 있음"
fi
