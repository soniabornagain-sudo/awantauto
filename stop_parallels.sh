#!/bin/bash

VM_NAME="Windows 11"

# VM 프로세스 실행 중이면 osascript로 강제 종료
if pgrep -x "prl_vm_app" > /dev/null; then
    echo "[1] Windows VM 종료 중..."
    osascript <<EOF
tell application "Parallels Desktop"
    tell virtual machine "$VM_NAME"
        stop with force
    end tell
end tell
EOF
    sleep 5
    echo "[1] Windows VM 종료 완료"
else
    echo "[1] VM이 이미 꺼져 있음"
fi

# Parallels Desktop 종료
if pgrep -x "prl_client_app" > /dev/null; then
    echo "[2] Parallels Desktop 종료 중..."
    osascript -e 'quit app "Parallels Desktop"'
    sleep 5
    echo "[2] Parallels Desktop 종료 완료"
else
    echo "[2] Parallels Desktop이 이미 꺼져 있음"
fi
