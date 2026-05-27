#!/bin/bash

VM_NAME="Windows 11"

# VM 상태 확인
VM_STATUS=$(prlctl list "$VM_NAME" --output status 2>/dev/null | tail -1)

if [ "$VM_STATUS" = "running" ]; then
    echo "[1] Windows VM 종료 중..."
    prlctl stop "$VM_NAME" --kill
    sleep 10
    echo "[1] Windows VM 종료 완료"
elif [ "$VM_STATUS" = "suspended" ] || [ "$VM_STATUS" = "paused" ]; then
    echo "[1] VM이 일시정지 상태 – 강제 종료..."
    prlctl stop "$VM_NAME" --kill
    sleep 5
    echo "[1] Windows VM 종료 완료"
else
    echo "[1] VM이 이미 꺼져 있음 (status: $VM_STATUS)"
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
